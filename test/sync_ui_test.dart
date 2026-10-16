import 'dart:io';
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
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'sync_fakes.dart';

DateTime t(int minute) => DateTime.utc(2026, 1, 1, 9, minute);

Book book(String uuid, String title, {String? isbn}) =>
    Book(uuid: uuid, title: title, isbn: isbn, createdAt: t(0), updatedAt: t(1));

/// ほかのパソコンが先に同期したかのように、クラウドに書籍を置く。
Future<void> putCloudBooks(MemoryDriveStore drive, List<SyncBook> books) => drive.upload(
      syncSnapshotFileName,
      Uint8List.fromList(SyncSnapshot(books: books).encode()),
      contentType: 'application/json',
    );

/// 想定外の例外を投げる Drive。
class _BrokenDrive extends MemoryDriveStore {
  @override
  Future<List<RemoteFile>> listSnapshots() async => throw ArgumentError('unexpected');
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

  group('SyncController の同期', () {
    test('同期すると最終同期日時を記録し、データが変わったら知らせる', () async {
      await putCloudBooks(drive, [SyncBook(uuid: 'r', title: 'クラウドの本', createdAt: t(0), updatedAt: t(1))]);
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await settle(sync);
      var changed = 0;
      sync.onLocalDataChanged = () => changed++;

      expect(await sync.syncNow(), isA<SyncDone>());
      expect(sync.lastSyncAt, isNotNull);
      expect(sync.lastFailure, isNull);
      expect(changed, 1);
      expect(repo.getAllBooks().single.title, 'クラウドの本');
    });

    test('失敗したら理由を残し、ログアウトしていれば何もしない', () async {
      await drive.upload(syncSnapshotFileName, Uint8List.fromList('{broken'.codeUnits), contentType: 'application/json');
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await settle(sync);
      expect(await sync.syncNow(), isNull);
      expect(sync.lastFailure, SyncFailure.remoteCorrupt);

      final out = fakeSyncController(repo, drive: drive);
      await settle(out);
      expect(await out.syncNow(), isNull);
      expect(out.lastFailure, isNull);
    });

    test('起動時に、前回測ったサーバー時刻との差を記録時刻に反映する', () {
      final state = MemorySyncStateStore()..state = const SyncState(clockOffset: Duration(minutes: -1));
      fakeSyncController(repo, drive: drive, state: state);
      expect(AppClock.offset, const Duration(minutes: -1));
    });

    test('同期の途中でログアウトしても、終わるのを待ってから記録を消す', () async {
      final state = MemorySyncStateStore();
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), state: state);
      await settle(sync);
      final running = sync.syncNow();
      await sync.signOut();
      await running;
      expect(state.state.hasSynced, isFalse, reason: '同期が記録を残した後で消している');
      expect(sync.state, SyncAuthState.signedOut);
    });

    test('想定外の失敗も「同期できませんでした」として残す', () async {
      final store = MemorySyncStateStore();
      final sync = SyncController(
        FakeGoogleAuth(stored: fakeAccount()),
        stateStore: store,
        engineFactory: (_) => SyncEngine(repository: repo, drive: _BrokenDrive(), state: store),
      );
      await settle(sync);
      expect(await sync.syncNow(), isNull);
      expect(sync.lastFailure, SyncFailure.other);
    });

    test('初めての同期の前のバックアップは、まとめて消せる', () async {
      final dir = await Directory.systemTemp.createTemp('colophon-sync-backups');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      await File('${dir.path}/colophon-before-first-sync-1.zip').writeAsBytes([1]);
      final sync = fakeSyncController(repo, drive: drive, backupDirectory: dir);
      await sync.deleteLocalBackups();
      expect(await dir.exists(), isFalse);
    });

    test('ログアウトすると同期の記録を消し、次は初めての同期として扱う', () async {
      final state = MemorySyncStateStore();
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount(), state: state);
      await settle(sync);
      await sync.syncNow();
      expect(state.state.hasSynced, isTrue);

      await sync.signOut();
      expect(state.state.hasSynced, isFalse);
      expect(sync.lastSyncAt, isNull);
    });
  });

  group('設定画面', () {
    Future<SettingsController> pumpApp(WidgetTester tester, SyncController sync) async {
      SharedPreferences.setMockInitialValues({'language': 'ja'});
      final settings = SettingsController(await SharedPreferences.getInstance());
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ColophonApp(settings: settings, repository: repo, sync: sync));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Google ドライブで同期'), 200);
      await tester.pumpAndSettle();
      return settings;
    }

    testWidgets('ログイン中は「今すぐ同期」と最終同期日時を出し、同期すると一覧にも反映する', (tester) async {
      await putCloudBooks(drive, [SyncBook(uuid: 'r', title: 'クラウドの本', createdAt: t(0), updatedAt: t(1))]);
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      expect(find.text('まだ同期していません'), findsOneWidget);

      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      expect(find.text('同期しました。'), findsOneWidget);
      expect(find.textContaining('最終同期:'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('クラウドの本'), findsOneWidget);
    });

    testWidgets('同期に失敗したら、理由を赤字で出す', (tester) async {
      await drive.upload(syncSnapshotFileName, Uint8List.fromList('{broken'.codeUnits), contentType: 'application/json');
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      expect(find.text('Google ドライブの同期データが壊れているため、同期を中止しました。'), findsWidgets);
    });

    testWidgets('初めての同期で両方にデータがあれば、冊数を見せて扱いを選んでもらう', (tester) async {
      await putCloudBooks(drive, [
        SyncBook(uuid: 'r1', title: 'クラウドの本', isbn: '9784309226712', createdAt: t(0), updatedAt: t(1)),
        SyncBook(uuid: 'r2', title: 'クラウドだけの本', createdAt: t(0), updatedAt: t(1)),
      ]);
      repo.saveBook(book('l1', 'この PC の本', isbn: '978-4-309-22671-2'));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);

      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      expect(find.text('初めての同期'), findsOneWidget);
      expect(find.textContaining('このパソコンに1冊、Google ドライブに2冊'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(repo.getAllBooks().map((b) => b.uuid), ['l1'], reason: 'キャンセルすれば何も変えない');

      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('同期する'));
      await tester.pumpAndSettle();
      expect(repo.getAllBooks().map((b) => b.uuid), unorderedEquals(['r1', 'r2']), reason: '既定の「統合」で同じ ISBN をまとめる');
    });

    Future<void> deleteAll(WidgetTester tester, {required String scope}) async {
      await tester.scrollUntilVisible(find.text('すべてのデータを削除'), 200);
      await tester.tap(find.text('すべてのデータを削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('削除へ進む'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(scope));
      await tester.tap(find.text('削除したデータは元に戻せないことを理解しました'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'すべて削除'));
      await tester.pumpAndSettle();
    }

    testWidgets('「このパソコンだけ」は同期をオフにしてから消し、クラウドには何もしない', (tester) async {
      repo.saveBook(book('u1', '本'));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      final cloud = SyncSnapshot.decode(drive.files.values.single.bytes);

      await deleteAll(tester, scope: 'このパソコンだけ');
      expect(repo.countBooks(), 0);
      expect(sync.state, SyncAuthState.signedOut);
      expect(SyncSnapshot.decode(drive.files.values.single.bytes).toJson(), cloud.toJson());
    });

    testWidgets('「すべてのパソコン」は、ほかのパソコンで足された書籍も含めて削除済みの印を送る', (tester) async {
      repo.saveBook(book('u1', '本'));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      // ほかのパソコンが、この後に1冊足して同期した
      final other = SyncSnapshot.decode(drive.files.values.single.bytes);
      await drive.upload(
        syncSnapshotFileName,
        Uint8List.fromList(SyncSnapshot(books: [
          ...other.books,
          SyncBook(uuid: 'o1', title: 'ほかの PC の本', createdAt: t(0), updatedAt: t(2)),
        ]).encode()),
        contentType: 'application/json',
        fileId: drive.files.keys.single,
      );

      await deleteAll(tester, scope: 'Google ドライブとすべてのパソコン');
      expect(repo.countBooks(), 0);
      expect(sync.state, SyncAuthState.signedOut);
      final cloud = SyncSnapshot.decode(drive.files.values.single.bytes);
      expect(cloud.books.map((b) => b.uuid), unorderedEquals(['u1', 'o1']));
      expect(cloud.books.every((b) => b.isDeleted), isTrue);
    });

    testWidgets('「すべてのパソコン」は、時計が進んだパソコンで付いた未来の日時の書籍も消し、書影もすぐ消す', (tester) async {
      // 一覧に表示されるので、縮小画像は付けない（画像として読めない仮のデータを避ける）
      repo.saveBook(Book(uuid: 'u1', title: '本', cover: Uint8List.fromList([1]), coverType: 'image/png',
          createdAt: t(0), updatedAt: t(1)));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      await tester.tap(find.text('今すぐ同期'));
      await tester.pumpAndSettle();
      final other = SyncSnapshot.decode(drive.files.values.firstWhere((f) => f.name == syncSnapshotFileName).bytes);
      final future = DateTime.now().toUtc().add(const Duration(days: 1));
      await drive.upload(
        syncSnapshotFileName,
        Uint8List.fromList(SyncSnapshot(books: [
          ...other.books,
          SyncBook(uuid: 'f1', title: '未来の本', createdAt: future, updatedAt: future),
        ]).encode()),
        contentType: 'application/json',
        fileId: drive.files.entries.firstWhere((e) => e.value.name == syncSnapshotFileName).key,
      );

      await deleteAll(tester, scope: 'Google ドライブとすべてのパソコン');
      final cloud = SyncSnapshot.decode(drive.files.values.single.bytes);
      expect(cloud.books.every((b) => b.isDeleted), isTrue);
      expect(drive.files.values.where((f) => f.name.startsWith(syncCoverPrefix)), isEmpty);
    });

    testWidgets('「すべてのパソコン」で、クラウドに読めない記録があって送れなければ、このパソコンも消さない', (tester) async {
      repo.saveBook(book('u1', '本'));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      await drive.upload(
        syncSnapshotFileName,
        Uint8List.fromList('{"version":1,"books":[{"title":"読めない記録"}]}'.codeUnits),
        contentType: 'application/json',
      );

      await deleteAll(tester, scope: 'Google ドライブとすべてのパソコン');
      expect(repo.countBooks(), 1);
      expect(sync.state, SyncAuthState.signedIn);
    });

    testWidgets('「すべてのパソコン」で Google ドライブに接続できなければ、何も消さない', (tester) async {
      repo.saveBook(book('u1', '本'));
      final sync = fakeSyncController(repo, drive: drive, account: fakeAccount());
      await pumpApp(tester, sync);
      await drive.upload(syncSnapshotFileName, Uint8List.fromList('{broken'.codeUnits), contentType: 'application/json');

      await deleteAll(tester, scope: 'Google ドライブとすべてのパソコン');
      expect(find.textContaining('何も削除していません'), findsOneWidget);
      expect(repo.countBooks(), 1);
      expect(sync.state, SyncAuthState.signedIn);
    });
  });
}
