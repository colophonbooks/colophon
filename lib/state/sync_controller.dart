import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../services/google_auth.dart';

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

/// Google ドライブ同期のログイン状態を保つ。同期の処理本体は後の工程で足す。
class SyncController extends ChangeNotifier {
  SyncController(this._auth) : _state = _auth.isConfigured ? SyncAuthState.loading : SyncAuthState.unavailable {
    if (_auth.isConfigured) unawaited(_restore());
  }

  final GoogleAuth _auth;
  SyncAuthState _state;
  GoogleAccount? _account;
  GoogleSignInFlow? _flow;
  AutoRefreshingAuthClient? _client;
  bool _disposed = false;

  SyncAuthState get state => _state;
  String? get accountEmail => _account?.email;

  /// ログイン中に表示する、ブラウザで開く URL（コピー用）
  Uri? get pendingAuthorizationUri => _flow?.authorizationUri;

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
      _set(SyncAuthState.signedIn);
    } on Object {
      _set(SyncAuthState.signedOut);
      rethrow;
    } finally {
      _flow = null;
    }
  }

  Future<void> cancelSignIn() async => _flow?.cancel();

  Future<void> signOut() async {
    final account = _account;
    if (account == null) return;
    _client?.close();
    _client = null;
    _account = null;
    _set(SyncAuthState.signedOut);
    await _auth.signOut(account);
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
