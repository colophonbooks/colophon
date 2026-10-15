import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as gdrive show DetailedApiRequestError;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

import '../data/book_repository.dart';
import '../services/app_clock.dart';
import '../services/cover_image.dart' as cover_image;
import 'drive_store.dart';
import 'sync_plan.dart';
import 'sync_snapshot.dart';
import 'sync_state.dart';

enum SyncFailure {
  /// 通信できない・Google 側が一時的に応答しない。時間をおいて再試行すればよい
  network,

  /// ログインし直す必要がある（許可が取り消された・期限切れなど）
  auth,

  /// 新しい版のアプリが書いた同期データ。アプリの更新が必要
  newerFormat,

  /// クラウドの同期データが壊れていて読めない
  remoteCorrupt,

  /// ほかの端末の送信と何度も重なった
  busy,

  /// クラウドにあるはずの書影がない
  missingCover,

  /// Google ドライブの容量が足りない
  quota,

  /// この端末の DB やバックアップの保存に失敗した
  localStorage,
  other,
}

class SyncException implements Exception {
  const SyncException(this.failure, [this.detail]);

  final SyncFailure failure;
  final String? detail;

  @override
  String toString() => 'SyncException(${failure.name}${detail == null ? '' : ': $detail'})';
}

sealed class SyncResult {
  const SyncResult();
}

/// 同期が終わった。
class SyncDone extends SyncResult {
  const SyncDone({
    required this.booksChanged,
    required this.notesChanged,
    required this.uploaded,
    this.remoteUnreadable = false,
  });

  /// この端末で書き換えた書籍・ノートの数（画面の再読み込みが要るか）
  final int booksChanged;
  final int notesChanged;
  final bool uploaded;

  /// クラウドに読めない記録があったため、送信を見合わせた
  final bool remoteUnreadable;

  bool get localChanged => booksChanged > 0 || notesChanged > 0;
}

/// 初めての同期で、この端末とクラウドの両方にデータがある。利用者に扱いを選んでもらってから、
/// [SyncEngine.sync] に [FirstSyncMode] を渡して呼び直す。
class SyncNeedsFirstChoice extends SyncResult {
  const SyncNeedsFirstChoice({required this.localBooks, required this.remoteBooks});

  final int localBooks;
  final int remoteBooks;
}

/// Google ドライブとの同期1回分を行う。
///
/// 手順: クラウドの同期データを取得 → 統合 → 足りない書影を取得 → （送る必要があれば）書影を送り、
/// クラウドがその間に書き換えられていないことを確かめてから同期データを送る → この端末へ書き込む。
/// 書き換えられていたら、取得からやり直す。途中で失敗しても、この端末の DB は書き込み前のまま。
class SyncEngine {
  SyncEngine({
    required this.repository,
    required this.drive,
    required this.state,
    this.backupBeforeFirstSync,
    Future<Uint8List?> Function(Uint8List bytes)? makeThumbnail,
    this.maxAttempts = 3,
    this.coverRetention = const Duration(days: 7),
    this.clockTolerance = const Duration(seconds: 5),
  }) : _makeThumbnail = makeThumbnail ?? cover_image.makeThumbnail;

  final BookRepository repository;
  final DriveStore drive;
  final SyncStateStore state;

  /// 初めての同期で、この端末のデータを書き換える前に呼ぶ（バックアップを取る）。
  final Future<void> Function()? backupBeforeFirstSync;
  final Future<Uint8List?> Function(Uint8List bytes) _makeThumbnail;
  final int maxAttempts;

  /// どの書籍からも使われなくなった書影を、Drive から消すまでの猶予。
  /// しばらく同期していなかった端末が古い同期データを元に送ってきても、書影を失わないようにする。
  final Duration coverRetention;

  /// サーバー時刻との差が、これ以上変わったときだけ補正し直す。
  final Duration clockTolerance;

  Future<SyncResult> sync({FirstSyncMode? firstSync}) async {
    try {
      return await _sync(firstSync);
    } on SyncException {
      rethrow;
    } on UnsupportedSyncFormatException {
      throw const SyncException(SyncFailure.newerFormat);
    } on FormatException catch (e) {
      throw SyncException(SyncFailure.remoteCorrupt, '$e');
    } on gdrive.DetailedApiRequestError catch (e) {
      throw SyncException(classifyApiError(e), '${e.status} ${e.message}');
    } on AccessDeniedException catch (e) {
      throw SyncException(SyncFailure.auth, '$e');
    } on ServerRequestFailedException catch (e) {
      // 更新用トークンが無効（invalid_grant）ならログインし直しが要る。それ以外は Google 側の一時的な失敗
      throw SyncException('$e'.contains('invalid_grant') ? SyncFailure.auth : SyncFailure.network, '$e');
    } on SocketException catch (e) {
      throw SyncException(SyncFailure.network, '$e');
    } on http.ClientException catch (e) {
      throw SyncException(SyncFailure.network, '$e');
    } on TimeoutException catch (e) {
      throw SyncException(SyncFailure.network, '$e');
    } on HandshakeException catch (e) {
      throw SyncException(SyncFailure.network, '$e');
    } on SqliteException catch (e) {
      throw SyncException(SyncFailure.localStorage, '$e');
    } on FileSystemException catch (e) {
      throw SyncException(SyncFailure.localStorage, '$e');
    } on StateError catch (e) {
      // applySync に書影が足りない（ほかの端末との行き違い）。次の同期で取り直せる
      throw SyncException(SyncFailure.missingCover, '$e');
    }
  }

  Future<SyncResult> _sync(FirstSyncMode? requestedMode) async {
    final saved = state.load();
    var hasSynced = saved.hasSynced;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final List<RemoteFile> snapshots;
      final SyncSnapshot? remote;
      try {
        snapshots = await drive.listSnapshots();
        _adoptServerClock();
        remote = await _downloadRemote(snapshots);
      } on gdrive.DetailedApiRequestError catch (e) {
        // 一覧を取ってから読むまでに、ほかの端末がファイルを消した。取得からやり直す
        if (e.status == 404) continue;
        rethrow;
      }
      final local = repository.exportSyncSnapshot();

      final firstSync = !hasSynced && remote != null && !remote.isEmpty && !local.isEmpty;
      if (firstSync && requestedMode == null) {
        return SyncNeedsFirstChoice(
          localBooks: local.books.where((b) => !b.isDeleted).length,
          remoteBooks: remote.books.where((b) => !b.isDeleted).length,
        );
      }
      final plan = planSync(local: local, remote: remote, firstSync: firstSync ? requestedMode : null, now: AppClock.now());
      // 同期データが2つある場合は、内容が同じでも1つにまとめるために送る
      final upload = plan.uploadNeeded || (snapshots.length > 1 && !plan.remoteUnreadable);

      final remoteCovers = await drive.listCovers();
      final covers = await _downloadCovers(plan, remoteCovers);

      // バックアップは Drive に何か書く前に取る（失敗したら、どこも変えずに終える）
      if (firstSync) await backupBeforeFirstSync?.call();

      // 必要な書影が Drive になければ、送る必要がない回でも補う（ほかの端末との行き違いで消えた場合など）
      await _uploadMissingCovers(plan, remoteCovers, covers);

      if (upload) {
        // ほかの端末がこの間に送っていたら、取得からやり直す（相手の変更を上書きしないため）
        if (!_sameFiles(snapshots, await drive.listSnapshots())) continue;
        final uploaded = await drive.upload(
          syncSnapshotFileName,
          Uint8List.fromList(plan.merged.encode()),
          contentType: 'application/json',
          fileId: snapshots.firstOrNull?.id,
        );
        for (final extra in snapshots.skip(1)) {
          await drive.delete(extra.id);
        }
        // 送った時点で「同期済み」を記録する。この後で止まっても、初めての同期の選択を聞き直さない
        hasSynced = true;
        await state.save(SyncState(hasSynced: true, lastSyncAt: saved.lastSyncAt, clockOffset: AppClock.offset));
        // 送った直後にほかの端末が上書きしていたら、取り込み直す
        final after = await drive.listSnapshots();
        if (after.length != 1 || after.single.id != uploaded.id || after.single.md5 != uploaded.md5) continue;
      }

      // 通信している間に利用者が編集していたら、その編集を上書きしないよう、この端末の今の内容と
      // 統合結果を突き合わせ直す。ここから書き込みまでは await を挟まない
      final fresh = repository.exportSyncSnapshot();
      final toApply = _sameSnapshot(fresh, local) ? plan : planSync(local: fresh, remote: plan.merged, now: AppClock.now());
      repository.applySync(books: toApply.booksToApply, notes: toApply.notesToApply, covers: covers);

      // 読めない記録があるときは、その記録が使う書影を消さないよう片付けをしない
      if (!plan.remoteUnreadable) await _tidyCovers(plan, remoteCovers);
      await state.save(SyncState(hasSynced: true, lastSyncAt: AppClock.now(), clockOffset: AppClock.offset));
      return SyncDone(
        booksChanged: toApply.booksToApply.length,
        notesChanged: toApply.notesToApply.length,
        uploaded: upload,
        remoteUnreadable: plan.remoteUnreadable,
      );
    }
    throw const SyncException(SyncFailure.busy);
  }

  /// サーバー時刻との差を記録時刻の補正に使う。Date ヘッダーは秒単位で揺れるので、
  /// 今の補正から [clockTolerance] を超えてずれたときだけ反映する（記録時刻が小刻みに戻らないように）。
  void _adoptServerClock() {
    final measured = drive.serverClockOffset;
    if (measured != null && (measured - AppClock.offset).abs() > clockTolerance) AppClock.offset = measured;
  }

  /// 同期データを取得する。2つ以上ある（2台が同時に初めて送った）場合は統合して1つとして扱う。
  Future<SyncSnapshot?> _downloadRemote(List<RemoteFile> snapshots) async {
    SyncSnapshot? merged;
    var unreadable = 0;
    for (final file in snapshots) {
      final bytes = await drive.download(file.id);
      final SyncSnapshot snapshot;
      try {
        snapshot = SyncSnapshot.fromJson(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
      } on UnsupportedSyncFormatException {
        rethrow;
      } on Object catch (e) {
        throw SyncException(SyncFailure.remoteCorrupt, '${file.id}: $e');
      }
      unreadable += snapshot.unreadableRecords;
      merged = merged == null ? snapshot : planSync(local: snapshot, remote: merged, now: AppClock.now()).merged;
    }
    if (merged == null) return null;
    return SyncSnapshot(books: merged.books, notes: merged.notes, unreadableRecords: unreadable);
  }

  /// この端末に書き込む書籍のうち、書影がまだこの端末にないもの。
  Iterable<String> _missingLocally(SyncPlan plan) => {
        for (final b in plan.booksToApply)
          if (!b.isDeleted && b.coverHash != null && repository.coverByHash(b.coverHash!) == null) b.coverHash!,
      };

  Future<Map<String, SyncCover>> _downloadCovers(SyncPlan plan, Map<String, RemoteFile> remoteCovers) async {
    final types = {for (final b in plan.booksToApply) if (b.coverHash != null) b.coverHash!: b.coverType};
    final result = <String, SyncCover>{};
    for (final hash in _missingLocally(plan)) {
      final file = remoteCovers[hash];
      if (file == null) throw SyncException(SyncFailure.missingCover, hash);
      final bytes = await drive.download(file.id);
      if (coverHashOf(bytes) != hash) throw SyncException(SyncFailure.missingCover, 'corrupt $hash');
      result[hash] = SyncCover(bytes: bytes, type: types[hash], thumbnail: await _makeThumbnail(bytes));
    }
    return result;
  }

  Future<void> _uploadMissingCovers(
      SyncPlan plan, Map<String, RemoteFile> remoteCovers, Map<String, SyncCover> downloaded) async {
    for (final hash in plan.coverHashes) {
      if (remoteCovers.containsKey(hash)) continue;
      final cover = repository.coverByHash(hash) ?? downloaded[hash];
      if (cover == null) continue; // この端末にもない書影（届いた書籍の書影の取得は、上で失敗している）
      await drive.upload('$syncCoverPrefix$hash', cover.bytes, contentType: cover.type ?? 'application/octet-stream');
    }
  }

  /// 使われなくなった書影に「使われなくなった日時」を付け、[coverRetention] が過ぎたら消す。
  /// また使われるようになった書影からは印を外す。失敗しても同期は成功とする。
  Future<void> _tidyCovers(SyncPlan plan, Map<String, RemoteFile> remoteCovers) async {
    final used = plan.coverHashes;
    final now = AppClock.now();
    try {
      for (final MapEntry(key: hash, value: file) in remoteCovers.entries) {
        final since = file.unusedSince;
        if (used.contains(hash)) {
          if (since != null) await drive.setUnusedSince(file.id, null);
        } else if (since == null) {
          await drive.setUnusedSince(file.id, now);
        } else if (now.difference(since) >= coverRetention) {
          await drive.delete(file.id);
        }
      }
    } on Object {
      return;
    }
  }

  static bool _sameSnapshot(SyncSnapshot a, SyncSnapshot b) => jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  static bool _sameFiles(List<RemoteFile> a, List<RemoteFile> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i].id == b[i].id && a[i].md5 == b[i].md5].every((same) => same);
}

/// Drive API のエラーを分類する。403 は理由によって、一時的な制限・権限がない・容量不足のどれにもなる。
SyncFailure classifyApiError(gdrive.DetailedApiRequestError e) =>
    classifyApiFailure(e.status ?? 0, {for (final d in e.errors) ?d.reason});

SyncFailure classifyApiFailure(int status, Set<String> reasons) {
  if (status == 401) return SyncFailure.auth;
  if (reasons.contains('storageQuotaExceeded')) return SyncFailure.quota;
  const temporary = {'rateLimitExceeded', 'userRateLimitExceeded', 'backendError', 'internalError'};
  if (status == 429 || status >= 500 || reasons.any(temporary.contains)) return SyncFailure.network;
  if (status == 403) return SyncFailure.auth;
  return SyncFailure.other;
}
