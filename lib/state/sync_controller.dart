import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../services/app_clock.dart';
import '../services/google_auth.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_plan.dart';
import '../sync/sync_state.dart';

enum SyncAuthState {
  /// このビルドには Google のクライアントが設定されていない
  unavailable,

  /// 保存したログイン情報を読み込み中
  loading,
  signedOut,

  /// ブラウザでのログインを待っている
  signingIn,
  signedIn,
}

/// Google ドライブ同期のログイン状態と、同期の実行・結果を保つ。
class SyncController extends ChangeNotifier {
  SyncController(
    this._auth, {
    SyncStateStore? stateStore,
    this.engineFactory,
    this.backupDirectory,
    this.autoSync = false,
    this.startupDelay = const Duration(seconds: 3),
    this.changeDelay = const Duration(seconds: 30),
    this.maxChangeDelay = const Duration(minutes: 5),
    this.retryDelays = const [
      Duration(minutes: 1),
      Duration(minutes: 2),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(minutes: 30),
    ],
  })  : _stateStore = stateStore ?? MemorySyncStateStore(),
        _state = _auth.isConfigured ? SyncAuthState.loading : SyncAuthState.unavailable {
    final saved = _stateStore.load();
    _lastSyncAt = saved.lastSyncAt;
    // まだ通信していない間の記録時刻も、前回測ったサーバー時刻との差で補正する
    // （保存先を渡されない仮の同期は、ほかの同期の補正を上書きしないよう何もしない）
    if (stateStore != null) AppClock.offset = saved.clockOffset;
    if (_auth.isConfigured) unawaited(_restore());
  }

  final GoogleAuth _auth;
  final SyncStateStore _stateStore;
  /// 同期エンジンを作る。null なら同期しない（テスト用）。
  final SyncEngine Function(AutoRefreshingAuthClient client)? engineFactory;

  /// 初めての同期の前に取るバックアップの置き場所。すべてのデータを削除するときに一緒に消す。
  final Directory? backupDirectory;

  /// 起動時・変更後・終了時に自動で同期するか（テストでは止めておく）。
  final bool autoSync;

  /// 起動してから最初の自動同期までの待ち時間。
  final Duration startupDelay;

  /// 最後の変更から自動同期までの待ち時間。続けて編集している間は同期を始めない。
  final Duration changeDelay;

  /// 最初の変更からの最長の待ち時間。編集し続けていても、これを過ぎたら同期する。
  final Duration maxChangeDelay;

  /// 一時的な失敗（通信できないなど）のあと、自動で再試行するまでの待ち時間（回数ごと。最後の値を繰り返す）。
  final List<Duration> retryDelays;
  SyncAuthState _state;
  GoogleAccount? _account;
  GoogleSignInFlow? _flow;
  AutoRefreshingAuthClient? _client;
  bool _disposed = false;

  bool _syncing = false;
  Future<SyncResult?>? _running;
  DateTime? _lastSyncAt;
  SyncFailure? _lastFailure;
  bool _lastRemoteUnreadable = false;
  Timer? _timer;

  /// 前回の同期の開始後に、利用者がデータを変えたか（終了時に同期するかの判断に使う）。
  bool _dirty = false;

  /// 同期中に変更があった。終わったらもう一度同期する。
  bool _again = false;
  bool _needsFirstChoice = false;
  int _dataRevision = 0;
  DateTime? _changedSince;
  int _retries = 0;

  /// 同期でこの端末のデータが変わったときに呼ぶ（一覧の再読み込みなど）。
  VoidCallback? onLocalDataChanged;

  /// 同期でこの端末のデータが変わるたびに増える。開いている画面が読み直すかの判断に使う。
  int get dataRevision => _dataRevision;

  /// 自動同期で、初めての同期の扱いを選んでもらう必要が分かった（自動では選ばない）。
  bool get needsFirstChoice => _needsFirstChoice;

  SyncAuthState get state => _state;
  String? get accountEmail => _account?.email;

  /// ログイン中に表示する、ブラウザで開く URL（コピー用）
  Uri? get pendingAuthorizationUri => _flow?.authorizationUri;

  bool get syncing => _syncing;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// 最後の同期の失敗の理由。成功したら null に戻る。
  SyncFailure? get lastFailure => _lastFailure;

  /// 最後の同期で、クラウドに読めない記録があった（送信を見合わせた）。
  bool get lastRemoteUnreadable => _lastRemoteUnreadable;

  /// Drive API を呼ぶためのクライアント。ログインしていなければ null。
  AutoRefreshingAuthClient? get client {
    final account = _account;
    if (account == null) return null;
    return _client ??= _auth.clientFor(account);
  }

  Future<void> _restore() async {
    _account = await _auth.restore();
    _set(_account == null ? SyncAuthState.signedOut : SyncAuthState.signedIn);
    if (_account != null) scheduleSync(startupDelay);
  }

  /// 利用者の操作でデータが変わった。少し待ってから同期する（自動同期が有効なとき）。
  void notifyLocalChange() {
    _dirty = true;
    if (_syncing) {
      _again = true;
      return;
    }
    // 最初の変更から [maxChangeDelay] を過ぎないよう、待ち時間を縮める
    final since = _changedSince ??= DateTime.now();
    final left = maxChangeDelay - DateTime.now().difference(since);
    scheduleSync(left < changeDelay ? (left.isNegative ? Duration.zero : left) : changeDelay);
  }

  /// [delay] 後に同期する。予約済みなら、予約し直す。
  void scheduleSync(Duration delay) {
    if (!autoSync || _disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      // 初めての同期の扱いは利用者が選ぶまで決まらないので、自動では進めない
      if (_needsFirstChoice) return;
      unawaited(syncNow());
    });
  }

  /// 終了する前に同期する必要がある（まだ送っていない利用者の変更がある）か。
  bool get hasUnsentChanges =>
      autoSync && _state == SyncAuthState.signedIn && !_needsFirstChoice && (_dirty || _again);

  /// 終了する前に、まだ送っていない変更があれば同期する（最大 [timeout] 待つ）。
  Future<void> syncBeforeExit({Duration timeout = const Duration(seconds: 10)}) async {
    // 送る必要があるのは、利用者の変更だけ（起動時の同期の予約などは、次に起動したときでよい）
    final pending = _dirty || _again;
    _timer?.cancel();
    _timer = null;
    if (!autoSync || _state != SyncAuthState.signedIn || _needsFirstChoice) return;
    try {
      await whenIdle().timeout(timeout);
      if (pending || _dirty) await syncNow().timeout(timeout);
    } on TimeoutException {
      // 終了を待たせすぎない。送れなかった変更は、次に起動したときに送る
    }
    // 編集画面の確認で終了を取りやめた場合に備えて、送れていない変更があれば予約し直す
    if (_dirty || _again) scheduleSync(changeDelay);
  }

  /// ブラウザでログインする。[openBrowser] には認可 URL が渡される。
  /// 失敗・取り消し時は [GoogleSignInException] を投げ、ログアウト状態に戻る。
  Future<void> signIn({
    required String successPage,
    required Future<void> Function(Uri uri) openBrowser,
  }) async {
    if (_state != SyncAuthState.signedOut) return;
    final GoogleSignInFlow flow;
    try {
      flow = await _auth.beginSignIn(successPage: successPage);
    } on Object catch (e) {
      throw GoogleSignInException(GoogleSignInFailure.failed, '$e');
    }
    _flow = flow;
    _set(SyncAuthState.signingIn);
    try {
      // ブラウザが開けなくても、画面に出した URL をコピーして続けられるので待ち続ける
      unawaited(openBrowser(flow.authorizationUri).catchError((Object _) {}));
      _account = await flow.result;
      _lastFailure = null;
      _set(SyncAuthState.signedIn);
    } on Object {
      _set(SyncAuthState.signedOut);
      rethrow;
    } finally {
      _flow = null;
    }
  }

  Future<void> cancelSignIn() async => _flow?.cancel();

  /// ログアウトする。同期の記録も消し、次にログインしたら初めての同期からやり直す
  /// （別のアカウントでログインする場合に、そちらのデータと正しく統合するため）。
  Future<void> signOut() async {
    _timer?.cancel();
    _timer = null;
    // 実行中の同期が終わってから消す。途中の同期が、消した後に記録や書き込みを残さないように
    await whenIdle();
    _timer?.cancel(); // 待っている間に、終わった同期が再試行を予約していることがある
    _timer = null;
    final account = _account;
    if (account == null) return;
    _client?.close();
    _client = null;
    _account = null;
    _lastSyncAt = null;
    _lastFailure = null;
    _lastRemoteUnreadable = false;
    _needsFirstChoice = false;
    _dirty = false;
    _again = false;
    _changedSince = null;
    _retries = 0;
    _set(SyncAuthState.signedOut);
    await _stateStore.clear();
    await _auth.signOut(account);
  }

  /// 今すぐ同期する。同期中・ログアウト中は何もせず null を返す。
  ///
  /// 失敗した場合は [lastFailure] に理由を残して null を返す。初めての同期で選択が必要なら
  /// [SyncNeedsFirstChoice] を返すので、利用者に選んでもらい [firstSync] を付けて呼び直す。
  Future<SyncResult?> syncNow({FirstSyncMode? firstSync, bool purgeUnusedCovers = false}) {
    final client = this.client;
    final factory = engineFactory;
    if (_syncing || client == null || factory == null) return Future.value();
    return _running = _run(factory(client), firstSync, purgeUnusedCovers);
  }

  /// 実行中の同期があれば、終わるまで待つ。
  Future<void> whenIdle() async {
    final running = _running;
    if (running != null) await running;
  }

  /// 初めての同期の前に取ったバックアップを消す（すべてのデータを削除するとき）。
  Future<void> deleteLocalBackups() async {
    final dir = backupDirectory;
    if (dir != null && await dir.exists()) await dir.delete(recursive: true);
  }

  Future<SyncResult?> _run(SyncEngine engine, FirstSyncMode? firstSync, bool purgeUnusedCovers) async {
    _syncing = true;
    _timer?.cancel();
    _timer = null;
    // ここまでの変更はこの同期で送る。この後の変更は notifyLocalChange で _dirty と _again が立つ
    final wasDirty = _dirty;
    _dirty = false;
    _changedSince = null;
    var retry = false;
    _set(_state);
    try {
      final result = await engine.sync(firstSync: firstSync, purgeUnusedCovers: purgeUnusedCovers);
      _lastFailure = null;
      _retries = 0;
      _needsFirstChoice = result is SyncNeedsFirstChoice;
      if (result is SyncDone) {
        _lastSyncAt = _stateStore.load().lastSyncAt;
        _lastRemoteUnreadable = result.remoteUnreadable;
        if (result.localChanged) {
          _dataRevision++;
          onLocalDataChanged?.call();
        }
      }
      return result;
    } on SyncException catch (e) {
      _lastFailure = e.failure;
      _dirty = _dirty || wasDirty; // 送れなかった変更は、まだ送っていない扱いに戻す
      retry = _isTemporary(e.failure);
      return null;
    } on Object {
      // 想定外の失敗も、理由が分からないまま黙って終わらせない
      _lastFailure = SyncFailure.other;
      _dirty = _dirty || wasDirty;
      retry = true;
      return null;
    } finally {
      _syncing = false;
      _running = null;
      if (_again) {
        _again = false;
        scheduleSync(const Duration(seconds: 2));
      } else if (retry && retryDelays.isNotEmpty) {
        // 一時的な失敗は、間隔をあけて自動で再試行する
        scheduleSync(retryDelays[_retries < retryDelays.length ? _retries : retryDelays.length - 1]);
        _retries++;
      }
      _set(_state);
    }
  }

  void _set(SyncAuthState state) {
    _state = state;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_flow?.cancel());
    _client?.close();
    super.dispose();
  }
}

/// 時間をおけば直る見込みのある失敗か。ログインし直し・容量・アプリの更新など、利用者の対応が
/// 要る失敗は自動では再試行しない（何度試しても同じ結果になるため）。
bool _isTemporary(SyncFailure failure) => switch (failure) {
      SyncFailure.network || SyncFailure.busy || SyncFailure.missingCover || SyncFailure.other => true,
      SyncFailure.auth ||
      SyncFailure.quota ||
      SyncFailure.newerFormat ||
      SyncFailure.remoteCorrupt ||
      SyncFailure.localStorage =>
        false,
    };
