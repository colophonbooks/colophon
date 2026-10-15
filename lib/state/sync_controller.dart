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

  /// 同期でこの端末のデータが変わったときに呼ぶ（一覧の再読み込みなど）。
  VoidCallback? onLocalDataChanged;

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
    // 実行中の同期が終わってから消す。途中の同期が、消した後に記録や書き込みを残さないように
    await whenIdle();
    final account = _account;
    if (account == null) return;
    _client?.close();
    _client = null;
    _account = null;
    _lastSyncAt = null;
    _lastFailure = null;
    _lastRemoteUnreadable = false;
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
    _set(_state);
    try {
      final result = await engine.sync(firstSync: firstSync, purgeUnusedCovers: purgeUnusedCovers);
      _lastFailure = null;
      if (result is SyncDone) {
        _lastSyncAt = _stateStore.load().lastSyncAt;
        _lastRemoteUnreadable = result.remoteUnreadable;
        if (result.localChanged) onLocalDataChanged?.call();
      }
      return result;
    } on SyncException catch (e) {
      _lastFailure = e.failure;
      return null;
    } on Object {
      // 想定外の失敗も、理由が分からないまま黙って終わらせない
      _lastFailure = SyncFailure.other;
      return null;
    } finally {
      _syncing = false;
      _running = null;
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
    unawaited(_flow?.cancel());
    _client?.close();
    super.dispose();
  }
}
