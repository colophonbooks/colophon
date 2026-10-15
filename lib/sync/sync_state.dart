import 'dart:convert';
import 'dart:io';

/// この端末の同期の記録。
class SyncState {
  const SyncState({this.hasSynced = false, this.lastSyncAt, this.clockOffset = Duration.zero});

  /// 一度でも同期したか。まだなら、次の同期は「初めての同期」として扱う。
  final bool hasSynced;
  final DateTime? lastSyncAt;

  /// 最後に測ったサーバー時刻との差。起動直後（まだ通信していない間）の記録時刻の補正に使う。
  final Duration clockOffset;
}

abstract class SyncStateStore {
  SyncState load();
  Future<void> save(SyncState state);

  /// ログアウト時に消す（別のアカウントでログインしたら、初めての同期からやり直すため）。
  Future<void> clear();
}

/// 本棚（DB）と同じフォルダの JSON ファイルに保存する。
///
/// 設定（SharedPreferences）に入れないのは、同期の記録は本棚に属するため。本棚のフォルダを
/// 分けて動かす試験版どうしで記録が混ざらず、本棚を別の場所へ移しても記録が一緒に動く。
class FileSyncStateStore implements SyncStateStore {
  FileSyncStateStore(this.file);

  final File file;

  @override
  SyncState load() {
    try {
      final j = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return SyncState(
        hasSynced: j['hasSynced'] as bool? ?? false,
        lastSyncAt: DateTime.tryParse(j['lastSyncAt'] as String? ?? '')?.toUtc(),
        clockOffset: Duration(milliseconds: j['clockOffsetMs'] as int? ?? 0),
      );
    } on Object {
      // ない・壊れている場合は、まだ同期していないものとして扱う
      return const SyncState();
    }
  }

  @override
  Future<void> save(SyncState state) async {
    // 書きかけで止まっても壊れないよう、別名で書いてから置き換える
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode({
      'hasSynced': state.hasSynced,
      'lastSyncAt': state.lastSyncAt?.toUtc().toIso8601String(),
      'clockOffsetMs': state.clockOffset.inMilliseconds,
    }), flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) await file.delete();
  }
}

class MemorySyncStateStore implements SyncStateStore {
  SyncState state = const SyncState();

  @override
  SyncState load() => state;

  @override
  Future<void> save(SyncState state) async => this.state = state;

  @override
  Future<void> clear() async => state = const SyncState();
}
