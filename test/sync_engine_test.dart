import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:colophon/data/app_database.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/models/book.dart';
import 'package:colophon/services/app_clock.dart';
import 'package:colophon/sync/drive_store.dart';
import 'package:colophon/sync/sync_backup.dart';
import 'package:colophon/sync/sync_engine.dart';
import 'package:colophon/sync/sync_plan.dart';
import 'package:colophon/sync/sync_snapshot.dart';
import 'package:colophon/sync/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' show DetailedApiRequestError;

DateTime t(int minute) => DateTime.utc(2026, 10, 15, 9, minute);

Book book(String uuid, int updated, {String title = '本', String? isbn, Uint8List? cover, List<Note> notes = const []}) =>
    Book(
      uuid: uuid,
      title: title,
      isbn: isbn,
      cover: cover,
      coverType: cover == null ? null : 'image/png',
      thumbnail: cover == null ? null : Uint8List.fromList([9]),
      notes: notes,
      createdAt: t(0),
      updatedAt: t(updated),
    );

/// 1台の端末（DB と同期の記録）。
class Device {
  Device(this.drive) : repo = BookRepository(openInMemoryDatabase());

  final BookRepository repo;
  final DriveStore drive;
  final state = MemorySyncStateStore();
  var backups = 0;

  SyncEngine engine({Duration coverRetention = const Duration(days: 7)}) => SyncEngine(
        repository: repo,
        drive: drive,
        state: state,
        backupBeforeFirstSync: () async => backups++,
        makeThumbnail: (bytes) async => Uint8List.fromList([0]),
        coverRetention: coverRetention,
      );

  Future<SyncResult> sync({FirstSyncMode? mode}) => engine().sync(firstSync: mode);

  List<String> titles() => [for (final b in repo.getAllBooks()) b.title]..sort();
}

SyncSnapshot cloudSnapshot(MemoryDriveStore drive) => SyncSnapshot.decode(
    drive.files.values.singleWhere((f) => f.name == syncSnapshotFileName).bytes);

void main() {
  late MemoryDriveStore drive;
  late Device a;
  late Device b;

  setUp(() {
    drive = MemoryDriveStore();
    a = Device(drive);
    b = Device(drive);
  });
  tearDown(() {
    a.repo.db.close();
    b.repo.db.close();
    AppClock.offset = Duration.zero;
  });

  test('最初の端末はそのまま送り、空の端末は確認なしで受け取る', () async {
    a.repo.saveBook(book('u1', 1, title: '一冊目', cover: Uint8List.fromList([1, 2, 3])));
    final first = await a.sync() as SyncDone;
    expect(first.uploaded, isTrue);
    expect(a.state.state.hasSynced, isTrue);
    expect(a.state.state.lastSyncAt, isNotNull);

    final second = await b.sync() as SyncDone;
    expect(second.booksChanged, 1);
    expect(b.titles(), ['一冊目']);
    expect(b.repo.getAllBooks().single.cover, [1, 2, 3]);
    expect(b.backups, 0, reason: '空の端末ではバックアップは要らない');
  });

  test('変わっていなければ、何度同期しても送らない', () async {
    a.repo.saveBook(book('u1', 1, cover: Uint8List.fromList([1])));
    await a.sync();
    await b.sync();
    final uploads = drive.uploads;
    for (final d in [a, b, a]) {
      final r = await d.sync() as SyncDone;
      expect(r.uploaded, isFalse);
      expect(r.localChanged, isFalse);
    }
    expect(drive.uploads, uploads);
  });

  test('初めての同期で両方にデータがあれば選んでもらい、選んだ方法で同期する前にバックアップを取る', () async {
    a.repo.saveBook(book('ua', 1, title: 'A の本', isbn: '9784309226712'));
    await a.sync();
    b.repo.saveBook(book('ub', 2, title: 'B の本', isbn: '978-4-309-22671-2'));
    b.repo.saveBook(book('ux', 2, title: 'B だけの本'));

    final ask = await b.sync();
    expect(ask, isA<SyncNeedsFirstChoice>());
    expect((ask as SyncNeedsFirstChoice).localBooks, 2);
    expect(ask.remoteBooks, 1);
    expect(b.state.state.hasSynced, isFalse);
    expect(b.titles(), ['B だけの本', 'B の本'], reason: '選ぶまでは何も変えない');

    await b.sync(mode: FirstSyncMode.merge);
    expect(b.backups, 1);
    expect(b.repo.getAllBooks().map((x) => x.uuid), unorderedEquals(['ua', 'ux']));

    await a.sync();
    expect(a.repo.getAllBooks().map((x) => x.uuid), unorderedEquals(['ua', 'ux']));
  });

  test('一度同期した端末では、初めての同期の選択は使わない', () async {
    a.repo.saveBook(book('u1', 1));
    await a.sync();
    a.repo.saveBook(book('u2', 2));
    final r = await a.sync(mode: FirstSyncMode.useRemote) as SyncDone;
    expect(r.uploaded, isTrue);
    expect(a.repo.getAllBooks(), hasLength(2));
  });

  test('ほかの端末が割り込んで送ったら、取り込み直してから送る', () async {
    a.repo.saveBook(book('u1', 1, title: 'A の本'));
    await a.sync();
    await b.sync();

    a.repo.saveBook(book('ua', 3, title: 'A で追加'));
    drive.onListSnapshots = () async {
      b.repo.saveBook(book('ub', 4, title: 'B で追加'));
      await b.sync();
    };
    await a.sync();

    expect(cloudSnapshot(drive).books.map((x) => x.uuid), unorderedEquals(['u1', 'ua', 'ub']));
    expect(a.titles(), ['A で追加', 'A の本', 'B で追加']);
  });

  test('割り込みが続けば、送らずに「混み合っている」で終える', () async {
    a.repo.saveBook(book('u1', 1));
    await a.sync();
    a.repo.saveBook(book('u2', 2));
    var n = 0;
    void interfere() {
      drive.onListSnapshots = () async {
        final id = drive.files.entries.firstWhere((e) => e.value.name == syncSnapshotFileName).key;
        await drive.upload(syncSnapshotFileName, Uint8List.fromList(SyncSnapshot(books: [
          SyncBook(uuid: 'x${n++}', title: 'x', createdAt: t(0), updatedAt: t(0)),
        ]).encode()), contentType: 'application/json', fileId: id);
        interfere();
      };
    }

    interfere();
    await expectLater(a.engine().sync(), throwsA(isA<SyncException>().having((e) => e.failure, 'failure', SyncFailure.busy)));
    expect(a.repo.getAllBooks(), hasLength(2), reason: 'この端末のデータはそのまま');
  });

  test('同期データが2つあれば統合して1つにまとめる', () async {
    for (final (uuid, title) in [('r1', '一つ目'), ('r2', '二つ目')]) {
      await drive.upload(
        syncSnapshotFileName,
        Uint8List.fromList(SyncSnapshot(books: [SyncBook(uuid: uuid, title: title, createdAt: t(0), updatedAt: t(1))]).encode()),
        contentType: 'application/json',
      );
    }
    await a.sync();
    expect(a.titles(), ['一つ目', '二つ目']);
    expect(drive.files.values.where((f) => f.name == syncSnapshotFileName), hasLength(1));
    expect(cloudSnapshot(drive).books, hasLength(2));
  });

  test('新しい版の同期データ・壊れた同期データは扱わず、上書きもしない', () async {
    a.repo.saveBook(book('u1', 1));
    await drive.upload(syncSnapshotFileName, Uint8List.fromList(utf8.encode(jsonEncode({'version': syncFormatVersion + 1}))),
        contentType: 'application/json');
    await expectLater(a.engine().sync(),
        throwsA(isA<SyncException>().having((e) => e.failure, 'failure', SyncFailure.newerFormat)));

    drive.files.clear();
    await drive.upload(syncSnapshotFileName, Uint8List.fromList(utf8.encode('{broken')), contentType: 'application/json');
    await expectLater(a.engine().sync(),
        throwsA(isA<SyncException>().having((e) => e.failure, 'failure', SyncFailure.remoteCorrupt)));
    expect(utf8.decode(drive.files.values.single.bytes), '{broken');
  });

  test('クラウドに書影がなければ、この端末を書き換えずに失敗する', () async {
    a.repo.saveBook(book('u1', 1, cover: Uint8List.fromList([5])));
    await a.sync();
    drive.files.removeWhere((_, f) => f.name.startsWith(syncCoverPrefix));
    await expectLater(b.engine().sync(),
        throwsA(isA<SyncException>().having((e) => e.failure, 'failure', SyncFailure.missingCover)));
    expect(b.repo.getAllBooks(), isEmpty);
    expect(b.state.state.hasSynced, isFalse);
  });

  test('クラウドに読めない記録があれば、取り込めるものだけ取り込み、送らずに知らせる', () async {
    await drive.upload(
      syncSnapshotFileName,
      Uint8List.fromList(utf8.encode(jsonEncode({
        'version': 1,
        'books': [
          {'uuid': 'r', 'title': 'クラウド', 'createdAt': t(0).toIso8601String(), 'updatedAt': t(1).toIso8601String()},
          {'title': '読めない'},
        ],
      }))),
      contentType: 'application/json',
    );
    final before = drive.uploads;
    a.repo.saveBook(book('u1', 1));
    final r = await a.sync(mode: FirstSyncMode.merge) as SyncDone;
    expect(r.remoteUnreadable, isTrue);
    expect(r.uploaded, isFalse);
    expect(drive.uploads, before);
    expect(a.titles(), ['クラウド', '本']);
  });

  test('サーバー時刻との差で記録時刻を補正し、次回の起動用に保存する', () async {
    drive.serverClockOffset = const Duration(minutes: -1);
    await a.sync();
    expect(AppClock.offset, const Duration(minutes: -1));
    expect(a.state.state.clockOffset, const Duration(minutes: -1));
  });

  test('サーバー時刻との差が少し変わっただけなら、補正し直さない', () async {
    AppClock.offset = const Duration(minutes: -1);
    drive.serverClockOffset = const Duration(minutes: -1, seconds: 2);
    await a.sync();
    expect(AppClock.offset, const Duration(minutes: -1));
  });

  test('サーバー時刻の差は、2秒未満なら誤差として 0 にする', () {
    final local = DateTime.utc(2026, 1, 1, 0, 0, 0);
    expect(measureClockOffset(local.add(const Duration(milliseconds: 1500)), local), Duration.zero);
    expect(measureClockOffset(local.add(const Duration(seconds: 61)), local), const Duration(seconds: 61));
  });

  test('使われなくなった書影は、猶予が過ぎてから Drive から消す', () async {
    a.repo.saveBook(book('u1', 1, cover: Uint8List.fromList([1])));
    await a.sync();
    final id = a.repo.getAllBooks().single.id;
    a.repo.saveBook(Book(
        id: id, uuid: 'u1', title: '本', cover: Uint8List.fromList([2]), coverType: 'image/png',
        thumbnail: Uint8List.fromList([9]), createdAt: t(0), updatedAt: t(2)));

    await a.engine(coverRetention: Duration.zero).sync();
    final covers = await drive.listCovers();
    expect(covers.keys, unorderedEquals([coverHashOf([1]), coverHashOf([2])]), reason: '使われなくなった日時を付けるだけ');
    expect(covers[coverHashOf([1])]!.unusedSince, isNotNull);
    expect(covers[coverHashOf([2])]!.unusedSince, isNull);

    await a.engine(coverRetention: const Duration(days: 7)).sync();
    expect((await drive.listCovers()).keys, hasLength(2), reason: '猶予の間は残す');

    await a.engine(coverRetention: Duration.zero).sync();
    expect((await drive.listCovers()).keys, [coverHashOf([2])]);
  });

  test('また使われるようになった書影からは、使われなくなった印を外す', () async {
    a.repo.saveBook(book('u1', 1, cover: Uint8List.fromList([1])));
    await a.sync();
    final cover = (await drive.listCovers()).values.single;
    await drive.setUnusedSince(cover.id, t(0));
    await a.sync();
    expect((await drive.listCovers()).values.single.unusedSince, isNull);
  });

  test('Drive から書影が消えていたら、送る必要がない回でも補う', () async {
    a.repo.saveBook(book('u1', 1, cover: Uint8List.fromList([4])));
    await a.sync();
    drive.files.removeWhere((_, f) => f.name.startsWith(syncCoverPrefix));
    final r = await a.sync() as SyncDone;
    expect(r.uploaded, isFalse);
    expect((await drive.listCovers()).keys, [coverHashOf([4])]);
  });

  test('同期の通信中に利用者が編集した書籍は、クラウドの古い内容で上書きしない', () async {
    a.repo.saveBook(book('x', 1, title: '最初'));
    await a.sync();
    await b.sync();
    b.repo.saveBook(Book(id: b.repo.getAllBooks().single.id, uuid: 'x', title: 'B で編集', cover: Uint8List.fromList([3]),
        coverType: 'image/png', thumbnail: Uint8List.fromList([9]), createdAt: t(0), updatedAt: t(8)));
    await b.sync();

    // A は t8 の版を受け取る途中（書影の取得中）に、t10 で編集する
    final engine = SyncEngine(
      repository: a.repo,
      drive: drive,
      state: a.state,
      makeThumbnail: (bytes) async {
        final id = a.repo.getAllBooks().single.id;
        a.repo.saveBook(Book(id: id, uuid: 'x', title: 'A で編集', createdAt: t(0), updatedAt: t(10)));
        return Uint8List.fromList([0]);
      },
    );
    await engine.sync();
    expect(a.titles(), ['A で編集']);

    await a.sync();
    await b.sync();
    expect(b.titles(), ['A で編集'], reason: '残った編集は次の同期で伝わる');
  });

  test('初めての同期の前のバックアップに失敗したら、Drive にも何も書かずに終える', () async {
    a.repo.saveBook(book('ua', 1));
    await a.sync();
    b.repo.saveBook(book('ub', 2));
    final uploads = drive.uploads;
    final engine = SyncEngine(
      repository: b.repo,
      drive: drive,
      state: b.state,
      backupBeforeFirstSync: () async => throw const FileSystemException('disk full'),
    );
    await expectLater(engine.sync(firstSync: FirstSyncMode.useLocal),
        throwsA(isA<SyncException>().having((e) => e.failure, 'failure', SyncFailure.localStorage)));
    expect(drive.uploads, uploads);
    expect(b.state.state.hasSynced, isFalse);
  });

  test('一覧の後にファイルが消えていたら、取得からやり直す', () async {
    final vanishing = _VanishingDrive();
    final device = Device(vanishing);
    addTearDown(() => device.repo.db.close());
    await vanishing.upload(syncSnapshotFileName,
        Uint8List.fromList(SyncSnapshot(books: [SyncBook(uuid: 'r', title: 'クラウド', createdAt: t(0), updatedAt: t(1))]).encode()),
        contentType: 'application/json');
    await device.sync();
    expect(device.titles(), ['クラウド']);
  });

  group('通信エラーの分類', () {
    Future<SyncFailure> failureOf(Object error) async {
      final engine = SyncEngine(repository: a.repo, drive: _ThrowingDrive(error), state: a.state);
      try {
        await engine.sync();
      } on SyncException catch (e) {
        return e.failure;
      }
      fail('例外にならなかった');
    }

    test('通信できない・一時的なエラーは network、認証のエラーは auth', () async {
      expect(await failureOf(const SocketException('offline')), SyncFailure.network);
      expect(await failureOf(DetailedApiRequestError(503, 'unavailable')), SyncFailure.network);
      expect(await failureOf(DetailedApiRequestError(429, 'rate')), SyncFailure.network);
      expect(await failureOf(DetailedApiRequestError(401, 'unauthorized')), SyncFailure.auth);
    });

    test('403 は理由で分ける（一時的な制限・容量不足・権限なし）', () {
      expect(classifyApiFailure(403, {'userRateLimitExceeded'}), SyncFailure.network);
      expect(classifyApiFailure(403, {'storageQuotaExceeded'}), SyncFailure.quota);
      expect(classifyApiFailure(403, {'insufficientPermissions'}), SyncFailure.auth);
      expect(classifyApiFailure(500, {}), SyncFailure.network);
      expect(classifyApiFailure(400, {}), SyncFailure.other);
    });
  });

  test('同期の記録は本棚のフォルダのファイルに保存し、壊れていれば未同期として扱う', () async {
    final dir = await Directory.systemTemp.createTemp('colophon-sync-state');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileSyncStateStore(File('${dir.path}/sync-state.json'));
    expect(store.load().hasSynced, isFalse, reason: 'ファイルがなければ未同期');

    await store.save(SyncState(hasSynced: true, lastSyncAt: t(5), clockOffset: const Duration(seconds: -61)));
    final loaded = FileSyncStateStore(File('${dir.path}/sync-state.json')).load();
    expect(loaded.hasSynced, isTrue);
    expect(loaded.lastSyncAt, t(5));
    expect(loaded.clockOffset, const Duration(seconds: -61));

    await File('${dir.path}/sync-state.json').writeAsString('{broken');
    expect(store.load().hasSynced, isFalse);

    await store.clear();
    expect(await File('${dir.path}/sync-state.json').exists(), isFalse);
  });

  test('初めての同期の前のバックアップは、新しい3つだけ残す', () async {
    final dir = await Directory.systemTemp.createTemp('colophon-sync-backup');
    addTearDown(() => dir.delete(recursive: true));
    a.repo.saveBook(book('u1', 1));
    for (var i = 0; i < 5; i++) {
      await writeSyncBackup(a.repo, dir, now: DateTime(2026, 10, 15, 9, i));
    }
    final names = dir.listSync().map((f) => f.uri.pathSegments.last).toList()..sort();
    expect(names, [
      'colophon-before-first-sync-20261015-090200.zip',
      'colophon-before-first-sync-20261015-090300.zip',
      'colophon-before-first-sync-20261015-090400.zip',
    ]);
  });
}

class _ThrowingDrive implements DriveStore {
  _ThrowingDrive(this.error);

  final Object error;

  @override
  Duration? get serverClockOffset => null;

  @override
  Future<List<RemoteFile>> listSnapshots() async => throw error;

  @override
  Future<Map<String, RemoteFile>> listCovers() async => throw error;

  @override
  Future<Uint8List> download(String fileId) async => throw error;

  @override
  Future<RemoteFile> upload(String name, Uint8List bytes, {required String contentType, String? fileId}) async =>
      throw error;

  @override
  Future<void> delete(String fileId) async => throw error;

  @override
  Future<void> setUnusedSince(String fileId, DateTime? at) async => throw error;
}

/// 最初の1回だけ、ファイルの読み出しで 404 を返す（ほかの端末が一覧の後に消した状況）。
class _VanishingDrive extends MemoryDriveStore {
  var vanished = false;

  @override
  Future<Uint8List> download(String fileId) async {
    if (!vanished) {
      vanished = true;
      throw DetailedApiRequestError(404, 'not found');
    }
    return super.download(fileId);
  }
}
