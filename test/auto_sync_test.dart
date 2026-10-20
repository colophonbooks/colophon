import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse;
import 'dart:typed_data';

import 'package:colophon/app.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/models/book.dart';
import 'package:colophon/services/app_clock.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:colophon/state/sync_controller.dart';
import 'package:colophon/sync/drive_store.dart';
import 'package:colophon/sync/sync_engine.dart';
import 'package:colophon/sync/sync_snapshot.dart';
import 'package:colophon/sync/sync_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' show DetailedApiRequestError;
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'sync_fakes.dart';

DateTime t(int minute) => DateTime.utc(2026, 1, 1, 9, minute);

Book book(String uuid, String title, {int? id, int updated = 1}) =>
    Book(id: id, uuid: uuid, title: title, createdAt: t(0), updatedAt: t(updated));

/// ほかのパソコンが同期したかのように、クラウドの内容を置き換える。
Future<void> putCloudBooks(MemoryDriveStore drive, List<SyncBook> books) async {
  final existing = drive.files.entries.where((e) => e.value.name == syncSnapshotFileName).map((e) => e.key);
  await drive.upload(
    syncSnapshotFileName,
    Uint8List.fromList(SyncSnapshot(books: books).encode()),
    contentType: 'application/json',
    fileId: existing.firstOrNull,
  );
}

/// 実時間で、条件が満たされるまで待つ（自動同期のタイマーを待つため）。
Future<void> waitUntil(bool Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) fail('時間内に条件を満たさなかった');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// 最初の [failures] 回だけ、同期データの一覧で [error] を投げる Drive。
class _FlakyDrive extends MemoryDriveStore {
  _FlakyDrive(this.failures, this.error);

  int failures;
  final Object error;

  @override
  Future<List<RemoteFile>> listSnapshots() async {
    if (failures > 0) {
      failures--;
      throw error;
    }
    return super.listSnapshots();
  }
}

/// [gate] が開くまで同期データの一覧を返さない Drive（同期中の画面を確かめるため）。
class _GatedDrive extends MemoryDriveStore {
  final gate = Completer<void>();

  @override
  Future<List<RemoteFile>> listSnapshots() async {
    await gate.future;
    return super.listSnapshots();
  }
}

/// 同期データの一覧がいつまでも返ってこない Drive（通信がとても遅い状況）。
class _StuckDrive extends MemoryDriveStore {
  @override
  Future<List<RemoteFile>> listSnapshots() => Completer<List<RemoteFile>>().future;
}

SyncController _controller(BookRepository repo, MemoryDriveStore drive,
        {Duration delay = const Duration(hours: 1), List<Duration> retry = const [Duration(milliseconds: 30)]}) {
  final state = MemorySyncStateStore();
  return SyncController(
    FakeGoogleAuth(stored: fakeAccount()),
    stateStore: state,
    autoSync: true,
    startupDelay: const Duration(hours: 1),
    changeDelay: delay,
    retryDelays: retry,
    engineFactory: (_) => SyncEngine(
      repository: repo,
      drive: drive,
      state: state,
      makeThumbnail: (bytes) async => Uint8List.fromList([0]),
    ),
  );
}

void main() {
  late BookRepository repo;
  late MemoryDriveStore drive;

  setUp(() {
    repo = newRepository();
    drive = MemoryDriveStore();
  });
  tearDown(() {
    repo.db.close();
    AppClock.offset = Duration.zero;
  });

  group('データの変更の知らせ', () {
    test('利用者の操作で変わったときに知らせ、同期の書き込みでは知らせない', () {
      var count = 0;
      repo.onChanged = () => count++;
      final id = repo.saveBook(book('u1', '本'));
      expect(count, 1);
      repo.deleteBook(id);
      expect(count, 2);

      repo.applySync(books: [SyncBook(uuid: 'r', title: 'クラウド', createdAt: t(0), updatedAt: t(1))], notes: const []);
      expect(count, 2, reason: '同期の書き込みでまた同期を予約しない');
    });
  });

  group('自動同期', () {
    test('起動時、ログインしていれば少し待ってから同期する', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true);
      addTearDown(sync.dispose);
      await waitUntil(() => sync.lastSyncAt != null);
      expect(drive.uploads, greaterThan(0));
    });

    test('自動同期が無効なら、起動しても変更しても同期しない', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      addTearDown(sync.dispose);
      await settle(sync);
      sync.notifyLocalChange();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(sync.lastSyncAt, isNull);
    });

    test('変更から少し待って同期し、続けて変更している間は待ち続ける', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true,
          delay: const Duration(milliseconds: 150));
      addTearDown(sync.dispose);
      repo.onChanged = sync.notifyLocalChange;
      await waitUntil(() => sync.lastSyncAt != null); // 起動時の同期
      final first = sync.lastSyncAt;

      for (var i = 0; i < 3; i++) {
        repo.saveBook(book('u$i', '本$i'));
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      expect(sync.lastSyncAt, first, reason: '最後の変更から待つ');
      await waitUntil(() => sync.lastSyncAt != first);
      expect(SyncSnapshot.decode(drive.files.values.single.bytes).books, hasLength(3));
    });

    test('同期中に変更されたら、終わってからもう一度同期する', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true,
          delay: const Duration(hours: 1));
      addTearDown(sync.dispose);
      repo.onChanged = sync.notifyLocalChange;
      await settle(sync);

      final running = sync.syncNow();
      repo.saveBook(book('late', '同期中に追加'));
      await running;
      await waitUntil(() => SyncSnapshot.decode(drive.files.values.single.bytes).books.any((b) => b.uuid == 'late'));
    });

    test('自動同期で初めての同期の選択が要ると分かったら、選ぶまで自動では進めない', () async {
      await putCloudBooks(drive, [SyncBook(uuid: 'r', title: 'クラウド', createdAt: t(0), updatedAt: t(1))]);
      repo.saveBook(book('l', 'この PC'));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true);
      addTearDown(sync.dispose);
      await waitUntil(() => sync.needsFirstChoice);
      final uploads = drive.uploads;

      sync.notifyLocalChange();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(drive.uploads, uploads);
      expect(repo.getAllBooks().single.uuid, 'l', reason: '勝手に統合しない');
    });

    test('終了するときは、まだ送っていない変更があれば同期し、なければ何もしない', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true,
          delay: const Duration(hours: 1));
      addTearDown(sync.dispose);
      repo.onChanged = sync.notifyLocalChange;
      await settle(sync);

      await sync.syncBeforeExit();
      expect(drive.uploads, 0, reason: '変更がなければ終了を待たせない');

      repo.saveBook(book('u1', '終了直前の本'));
      await sync.syncBeforeExit();
      expect(SyncSnapshot.decode(drive.files.values.single.bytes).books.single.title, '終了直前の本');
    });

    test('スマホでアプリが裏に回ったら、まだ送っていない変更を待たずに送る', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true,
          delay: const Duration(hours: 1));
      addTearDown(sync.dispose);
      repo.onChanged = sync.notifyLocalChange;
      await settle(sync);

      sync.onBackgrounded();
      await sync.whenIdle();
      expect(drive.uploads, 0, reason: '送るものがなければ通信しない');

      repo.saveBook(book('u1', '裏に回る前の本'));
      sync.onBackgrounded();
      await waitUntil(() => drive.uploads == 1);
      await sync.whenIdle();
      expect(SyncSnapshot.decode(drive.files.values.single.bytes).books.single.title, '裏に回る前の本');
    });

    test('スマホでアプリに戻ったら、しばらく同期していなければ同期し、直後なら同期しない', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true,
          delay: const Duration(hours: 1));
      addTearDown(sync.dispose);
      await settle(sync);
      await putCloudBooks(drive, [SyncBook(uuid: 'c1', title: 'ほかの端末の本', createdAt: t(0), updatedAt: t(1))]);

      sync.onResumed();
      await waitUntil(() => sync.lastSyncAt != null);
      await sync.whenIdle();
      expect(repo.getAllBooks().single.title, 'ほかの端末の本', reason: '前回の同期がないので同期する');

      final last = sync.lastSyncAt;
      sync.onResumed();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sync.lastSyncAt, last, reason: '同期した直後なので通信しない');
    });

    test('スマホでアプリに戻っても、ログインしていなければ同期せず、通信できずに失敗した後は再試行の予定を待つ', () async {
      final signedOut = fakeSyncController(repo, drive: drive, autoSync: true, delay: const Duration(hours: 1));
      addTearDown(signedOut.dispose);
      await settle(signedOut);
      signedOut.onResumed();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(drive.uploads, 0);

      final flaky = _FlakyDrive(1, const SocketException('offline'));
      final sync = _controller(repo, flaky, retry: const [Duration(hours: 1)]);
      addTearDown(sync.dispose);
      await settle(sync);
      await sync.syncNow();
      expect(sync.lastFailure, SyncFailure.network);

      sync.onResumed();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(flaky.failures, 0);
      expect(sync.lastFailure, SyncFailure.network, reason: '戻っただけでは試し直さない（1時間後の再試行を待つ）');
    });

    test('通信できずに失敗したら、少し待って自動で再試行する', () async {
      final flaky = _FlakyDrive(1, const SocketException('offline'));
      final sync = _controller(repo, flaky);
      addTearDown(sync.dispose);
      await settle(sync);
      repo.onChanged = sync.notifyLocalChange;
      repo.saveBook(book('u1', '本'));

      expect(await sync.syncNow(), isNull);
      expect(sync.lastFailure, SyncFailure.network);
      await waitUntil(() => sync.lastFailure == null && sync.lastSyncAt != null);
      expect(SyncSnapshot.decode(flaky.files.values.single.bytes).books.single.title, '本');
    });

    test('ログインし直しが要る失敗は、自動では再試行しない', () async {
      final flaky = _FlakyDrive(1, DetailedApiRequestError(401, 'unauthorized'));
      final sync = _controller(repo, flaky);
      addTearDown(sync.dispose);
      await settle(sync);
      expect(await sync.syncNow(), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(sync.lastFailure, SyncFailure.auth);
      expect(sync.lastSyncAt, isNull);
    });

    test('失敗した同期の変更は「まだ送っていない」に戻り、終了時に送る', () async {
      final flaky = _FlakyDrive(1, const SocketException('offline'));
      final sync = _controller(repo, flaky, retry: const []);
      addTearDown(sync.dispose);
      await settle(sync);
      repo.onChanged = sync.notifyLocalChange;
      repo.saveBook(book('u1', '本'));
      await sync.syncNow();

      await sync.syncBeforeExit();
      expect(SyncSnapshot.decode(flaky.files.values.single.bytes).books.single.title, '本');
    });

    test('編集し続けていても、最初の変更から最長の待ち時間を過ぎたら同期する', () async {
      final state = MemorySyncStateStore();
      final sync = SyncController(
        FakeGoogleAuth(stored: fakeAccount()),
        stateStore: state,
        autoSync: true,
        startupDelay: const Duration(hours: 1),
        changeDelay: const Duration(milliseconds: 150),
        maxChangeDelay: const Duration(milliseconds: 250),
        engineFactory: (_) => SyncEngine(repository: repo, drive: drive, state: state),
      );
      addTearDown(sync.dispose);
      await settle(sync);
      repo.onChanged = sync.notifyLocalChange;
      final end = DateTime.now().add(const Duration(milliseconds: 700));
      var i = 0;
      while (DateTime.now().isBefore(end) && sync.lastSyncAt == null) {
        repo.saveBook(book('u${i++}', '本'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(sync.lastSyncAt, isNotNull, reason: '50ms ごとに編集し続けても、250ms 程度で同期が始まる');
    });

    test('ログアウトすると、予約していた同期を取りやめる', () async {
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), autoSync: true,
          delay: const Duration(milliseconds: 50));
      addTearDown(sync.dispose);
      await settle(sync);
      await sync.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(drive.uploads, 0);
    });
  });

  group('終了時の同期の画面', () {
    Future<SyncController> pumpWithChange(WidgetTester tester, MemoryDriveStore drive) async {
      SharedPreferences.setMockInitialValues({'language': 'ja'});
      final settings = SettingsController(await SharedPreferences.getInstance());
      final state = MemorySyncStateStore();
      final sync = SyncController(
        FakeGoogleAuth(stored: fakeAccount()),
        stateStore: state,
        autoSync: true,
        startupDelay: const Duration(hours: 1),
        changeDelay: const Duration(hours: 1),
        engineFactory: (_) => SyncEngine(repository: repo, drive: drive, state: state),
      );
      repo.onChanged = sync.notifyLocalChange;
      await tester.pumpWidget(ColophonApp(settings: settings, repository: repo, sync: sync));
      await tester.pumpAndSettle();
      return sync;
    }

    /// アプリが裏に回る（前面 → 操作不可 → 非表示）。
    void hideApp(WidgetTester tester) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }

    testWidgets('スマホでは、アプリが裏に回ると送っていない変更を同期する', (tester) async {
      final drive = MemoryDriveStore();
      final sync = await pumpWithChange(tester, drive);
      addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      repo.saveBook(book('u1', '裏に回る前の本'));

      hideApp(tester);
      await tester.runAsync(sync.whenIdle);

      expect(SyncSnapshot.decode(drive.files.values.single.bytes).books.single.title, '裏に回る前の本');
    });

    testWidgets('パソコンでは、最小化しても同期しない（変更から少し待って同期する）',
        variant: TargetPlatformVariant.only(TargetPlatform.windows), (tester) async {
      final drive = MemoryDriveStore();
      final sync = await pumpWithChange(tester, drive);
      addTearDown(() => tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed));
      repo.saveBook(book('u1', '最小化する前の本'));

      hideApp(tester);
      await tester.runAsync(sync.whenIdle);

      expect(drive.uploads, 0);
      // 変更から1時間後の同期の予約が残るので、画面ごと片付けて取りやめる
      await tester.pumpWidget(const SizedBox());
      sync.dispose();
    });

    testWidgets('送っていない変更があれば「同期しています」を出し、同期してから終了する', (tester) async {
      final drive = _GatedDrive();
      await pumpWithChange(tester, drive);
      repo.saveBook(book('u1', '終了前の本'));

      final exit = tester.binding.handleRequestAppExit();
      // 終了の要求は登録順に1つずつ伝わるので、画面が描かれるまで2回更新する
      await tester.pump();
      await tester.pump();
      expect(find.text('Google ドライブと同期しています…'), findsOneWidget);
      drive.gate.complete();
      await tester.pumpAndSettle();
      expect(await exit, AppExitResponse.exit);
      expect(find.text('Google ドライブと同期しています…'), findsNothing);
      expect(SyncSnapshot.decode(drive.files.values.single.bytes).books.single.title, '終了前の本');
    });

    testWidgets('「同期せずに終了」を押せば、同期を待たずに終了する', (tester) async {
      final stuck = _StuckDrive();
      await pumpWithChange(tester, stuck);
      repo.saveBook(book('u1', '本'));

      final exit = tester.binding.handleRequestAppExit();
      // 終了の要求は登録順に1つずつ伝わるので、画面が描かれるまで2回更新する
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('同期せずに終了'));
      await tester.pumpAndSettle();
      expect(await exit, AppExitResponse.exit);
      // 実際の終了ではここでアプリが閉じる。テストでは、待ち時間の上限のタイマーを片付ける
      await tester.pump(const Duration(seconds: 21));
    });

    testWidgets('送っていない変更がなければ、画面を出さずにすぐ終了する', (tester) async {
      await pumpWithChange(tester, drive);
      final exit = tester.binding.handleRequestAppExit();
      // 終了の要求は登録順に1つずつ伝わるので、画面が描かれるまで2回更新する
      await tester.pump();
      await tester.pump();
      expect(find.text('Google ドライブと同期しています…'), findsNothing);
      expect(await exit, AppExitResponse.exit);
      expect(drive.uploads, 0);
    });
  });

  group('開いている書籍の画面', () {
    Future<SyncController> openBook(WidgetTester tester) async {
      repo.saveBook(book('x', '元の書名'));
      SharedPreferences.setMockInitialValues({'language': 'ja'});
      final settings = SettingsController(await SharedPreferences.getInstance());
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ColophonApp(settings: settings, repository: repo, sync: sync));
      await tester.pumpAndSettle();
      await tester.runAsync(() => sync.syncNow());
      await tester.tap(find.text('元の書名'));
      await tester.pumpAndSettle();
      expect(find.text('元の書名'), findsWidgets);
      return sync;
    }

    testWidgets('同期で書籍が変わったら、見ている画面も新しい内容になる', (tester) async {
      final sync = await openBook(tester);
      final cloud = SyncSnapshot.decode(drive.files.values.single.bytes);
      final x = cloud.books.single;
      await putCloudBooks(drive, [
        SyncBook(uuid: x.uuid, title: 'ほかの PC で直した書名', createdAt: x.createdAt, updatedAt: t(30)),
      ]);
      expect(await tester.runAsync(() => sync.syncNow()), isA<SyncDone>());
      await tester.pumpAndSettle();
      expect(find.text('ほかの PC で直した書名'), findsWidgets);
    });

    testWidgets('編集中にほかのパソコンで削除された書籍は、保存しても復活させずに閉じる', (tester) async {
      final sync = await openBook(tester);
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '元の書名'), '書き換え中');
      await tester.pumpAndSettle();

      final x = SyncSnapshot.decode(drive.files.values.single.bytes).books.single;
      await putCloudBooks(drive, [SyncBook.tombstone(x.uuid, createdAt: x.createdAt, at: t(30))]);
      await tester.runAsync(() => sync.syncNow());
      await tester.pumpAndSettle();
      expect(find.text('書き換え中'), findsWidgets, reason: '編集中の入力はそのまま');

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(find.text('この書籍は、ほかの端末で削除されました。'), findsOneWidget);
      expect(repo.getAllBooks(), isEmpty, reason: '削除された書籍を復活させない');
    });

    testWidgets('ほかのパソコンで削除されたら、知らせて画面を閉じる', (tester) async {
      final sync = await openBook(tester);
      final x = SyncSnapshot.decode(drive.files.values.single.bytes).books.single;
      await putCloudBooks(drive, [SyncBook.tombstone(x.uuid, createdAt: x.createdAt, at: t(30))]);
      await tester.runAsync(() => sync.syncNow());
      await tester.pumpAndSettle();
      expect(find.text('この書籍は、ほかの端末で削除されました。'), findsOneWidget);
      expect(find.textContaining('まだ書籍がありません'), findsOneWidget, reason: '一覧に戻る');
    });
  });
}
