import 'package:shared_preferences/shared_preferences.dart';

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

class PrefsSyncStateStore implements SyncStateStore {
  PrefsSyncStateStore(this._prefs);

  final SharedPreferences _prefs;

  static const _hasSynced = 'syncHasSynced';
  static const _lastSyncAt = 'syncLastAt';
  static const _clockOffset = 'syncClockOffsetMs';

  @override
  SyncState load() => SyncState(
        hasSynced: _prefs.getBool(_hasSynced) ?? false,
        lastSyncAt: DateTime.tryParse(_prefs.getString(_lastSyncAt) ?? '')?.toUtc(),
        clockOffset: Duration(milliseconds: _prefs.getInt(_clockOffset) ?? 0),
      );

  @override
  Future<void> save(SyncState state) async {
    await _prefs.setBool(_hasSynced, state.hasSynced);
    if (state.lastSyncAt case final at?) await _prefs.setString(_lastSyncAt, at.toUtc().toIso8601String());
    await _prefs.setInt(_clockOffset, state.clockOffset.inMilliseconds);
  }

  @override
  Future<void> clear() async {
    for (final key in [_hasSynced, _lastSyncAt, _clockOffset]) {
      await _prefs.remove(key);
    }
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
