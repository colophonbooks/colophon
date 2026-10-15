import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// 同期データのファイル名（appDataFolder 直下）。
const syncSnapshotFileName = 'colophon-sync.json';

/// 書影のファイル名の接頭辞。後ろに SHA-256（16進）を付ける。
const syncCoverPrefix = 'cover-';

/// Drive 上のファイルの情報。
class RemoteFile {
  const RemoteFile({required this.id, required this.name, this.md5, this.modifiedTime, this.unusedSince});

  final String id;
  final String name;

  /// 中身の MD5。中身が変わったかどうかの判定に使う（版番号は中身が同じでも進むことがあるため）。
  final String? md5;
  final DateTime? modifiedTime;

  /// 書影が、どの書籍からも使われなくなった日時（ファイルの appProperties に記録する）。
  /// 使われている書影では null。
  final DateTime? unusedSince;
}

/// 同期で使う Drive の操作。テストではメモリ上の偽物に差し替える。
abstract class DriveStore {
  /// 同期データのファイル（ふつうは1つ。2台が同時に初めて送ると2つになることがある）。古い順。
  Future<List<RemoteFile>> listSnapshots();

  /// 書影のファイル。キーは SHA-256。
  Future<Map<String, RemoteFile>> listCovers();

  Future<Uint8List> download(String fileId);

  /// [fileId] があれば上書き、なければ新しく作る。
  Future<RemoteFile> upload(String name, Uint8List bytes, {required String contentType, String? fileId});

  Future<void> delete(String fileId);

  /// 書影が使われなくなった日時を記録する（null で消す）。
  Future<void> setUnusedSince(String fileId, DateTime? at);

  /// 最後の通信で分かった、この端末の時計とサーバー時刻の差（サーバー − 端末）。分からなければ null。
  Duration? get serverClockOffset;
}

/// Google ドライブの appDataFolder を使う実装。
class GoogleDriveStore implements DriveStore {
  GoogleDriveStore(http.Client authClient) : _clock = _ClockClient(authClient) {
    _api = drive.DriveApi(_clock);
  }

  final _ClockClient _clock;
  late final drive.DriveApi _api;

  @override
  Duration? get serverClockOffset => _clock.offset;

  @override
  Future<List<RemoteFile>> listSnapshots() async {
    final files = await _listAll("name = '$syncSnapshotFileName'", orderBy: 'createdTime');
    return files.toList();
  }

  @override
  Future<Map<String, RemoteFile>> listCovers() async => {
        for (final f in await _listAll("name contains '$syncCoverPrefix'"))
          if (f.name.startsWith(syncCoverPrefix)) f.name.substring(syncCoverPrefix.length): f,
      };

  Future<List<RemoteFile>> _listAll(String q, {String? orderBy}) async {
    final result = <RemoteFile>[];
    String? pageToken;
    do {
      final page = await _api.files.list(
        spaces: 'appDataFolder',
        q: '$q and trashed = false',
        orderBy: orderBy,
        pageSize: 1000,
        pageToken: pageToken,
        $fields: 'nextPageToken, files(id, name, md5Checksum, modifiedTime, appProperties)',
      );
      for (final f in page.files ?? const <drive.File>[]) {
        result.add(_remote(f));
      }
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return result;
  }

  @override
  Future<Uint8List> download(String fileId) async {
    final media = await _api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final builder = BytesBuilder(copy: false);
    await media.stream.forEach(builder.add);
    return builder.takeBytes();
  }

  @override
  Future<RemoteFile> upload(String name, Uint8List bytes, {required String contentType, String? fileId}) async {
    final media = drive.Media(Stream.value(bytes), bytes.length, contentType: contentType);
    const fields = 'id, name, md5Checksum, modifiedTime';
    final file = fileId == null
        ? await _api.files.create(
            drive.File()
              ..name = name
              ..parents = ['appDataFolder'],
            uploadMedia: media,
            $fields: fields,
          )
        : await _api.files.update(drive.File(), fileId, uploadMedia: media, $fields: fields);
    return _remote(file);
  }

  @override
  Future<void> delete(String fileId) => _api.files.delete(fileId);

  @override
  Future<void> setUnusedSince(String fileId, DateTime? at) async {
    await _api.files.update(
      drive.File()..appProperties = {_unusedSinceKey: at?.toUtc().toIso8601String()},
      fileId,
      $fields: 'id',
    );
  }

  static const _unusedSinceKey = 'unusedSince';

  static RemoteFile _remote(drive.File f) => RemoteFile(
        id: f.id!,
        name: f.name ?? '',
        md5: f.md5Checksum,
        modifiedTime: f.modifiedTime,
        unusedSince: DateTime.tryParse(f.appProperties?[_unusedSinceKey] ?? '')?.toUtc(),
      );
}

/// 応答の Date ヘッダーから、サーバー時刻との差を測る HTTP クライアント。
class _ClockClient extends http.BaseClient {
  _ClockClient(this._inner);

  final http.Client _inner;
  Duration? offset;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    final date = response.headers['date'];
    if (date != null) {
      try {
        offset = measureClockOffset(HttpDate.parse(date), DateTime.now().toUtc());
      } on HttpException {
        // 読めない Date ヘッダーは無視する
      }
    }
    return response;
  }

  @override
  void close() => _inner.close();
}

/// サーバー時刻と端末の時刻の差。Date ヘッダーは秒単位なので、2秒未満の差は誤差として 0 にする。
Duration measureClockOffset(DateTime server, DateTime local) {
  final diff = server.difference(local);
  return diff.abs() < const Duration(seconds: 2) ? Duration.zero : diff;
}

/// テスト用の、メモリ上の Drive。
class MemoryDriveStore implements DriveStore {
  final files = <String, ({String name, Uint8List bytes, DateTime modified})>{};
  final unusedSince = <String, DateTime>{};
  var _nextId = 0;
  int uploads = 0;

  @override
  Duration? serverClockOffset;

  /// 次の listSnapshots の直後に呼ばれる。ほかの端末が割り込んで書き換える状況を再現する。
  FutureOr<void> Function()? onListSnapshots;

  RemoteFile _remote(String id) {
    final f = files[id]!;
    return RemoteFile(
        id: id, name: f.name, md5: md5.convert(f.bytes).toString(), modifiedTime: f.modified, unusedSince: unusedSince[id]);
  }

  @override
  Future<List<RemoteFile>> listSnapshots() async {
    final result = [
      for (final e in files.entries)
        if (e.value.name == syncSnapshotFileName) _remote(e.key),
    ];
    final hook = onListSnapshots;
    onListSnapshots = null;
    await hook?.call();
    return result;
  }

  @override
  Future<Map<String, RemoteFile>> listCovers() async => {
        for (final e in files.entries)
          if (e.value.name.startsWith(syncCoverPrefix)) e.value.name.substring(syncCoverPrefix.length): _remote(e.key),
      };

  @override
  Future<Uint8List> download(String fileId) async {
    final f = files[fileId];
    if (f == null) throw StateError('no file $fileId');
    return f.bytes;
  }

  @override
  Future<RemoteFile> upload(String name, Uint8List bytes, {required String contentType, String? fileId}) async {
    uploads++;
    final id = fileId ?? 'f${_nextId++}';
    files[id] = (name: name, bytes: bytes, modified: DateTime.now().toUtc());
    return _remote(id);
  }

  @override
  Future<void> delete(String fileId) async {
    files.remove(fileId);
    unusedSince.remove(fileId);
  }

  @override
  Future<void> setUnusedSince(String fileId, DateTime? at) async {
    if (at == null) {
      unusedSince.remove(fileId);
    } else {
      unusedSince[fileId] = at;
    }
  }
}
