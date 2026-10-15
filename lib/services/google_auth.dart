import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// 同期に使う Google の権限。Drive のアプリ専用領域（appDataFolder）だけを読み書きできる。
const googleDriveScopes = [drive.DriveApi.driveAppdataScope];

/// Google Cloud に登録したデスクトップアプリ用のクライアント。
///
/// 値はリポジトリに含めず、ビルド時に `--dart-define-from-file` で渡す（BUILDING.md）。
/// 渡さずにビルドしたアプリでは同期を使えない。
class GoogleOAuthConfig {
  const GoogleOAuthConfig({required this.clientId, required this.clientSecret});

  const GoogleOAuthConfig.fromEnvironment()
      : clientId = const String.fromEnvironment('COLOPHON_GOOGLE_CLIENT_ID'),
        clientSecret = const String.fromEnvironment('COLOPHON_GOOGLE_CLIENT_SECRET');

  final String clientId;

  /// デスクトップアプリでは秘密として扱えない値（Google の説明どおり）。PKCE と組み合わせて使う。
  final String clientSecret;

  bool get isConfigured => clientId.isNotEmpty;

  ClientId get _clientId => ClientId(clientId, clientSecret.isEmpty ? null : clientSecret);
}

// ---------------------------------------------------------------------------
// PKCE と認可 URL（RFC 7636・Google のネイティブアプリ向け手順）
// ---------------------------------------------------------------------------

const _unreserved = '0123456789-._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

String createCodeVerifier([Random? random]) {
  final rnd = random ?? Random.secure();
  return List.generate(64, (_) => _unreserved[rnd.nextInt(_unreserved.length)]).join();
}

String codeChallengeFor(String verifier) =>
    base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

String createState([Random? random]) {
  final rnd = random ?? Random.secure();
  return base64UrlEncode(List.generate(24, (_) => rnd.nextInt(256))).replaceAll('=', '');
}

Uri buildAuthorizationUri({
  required String clientId,
  required String redirectUri,
  required String codeVerifier,
  required String state,
  List<String> scopes = googleDriveScopes,
}) =>
    Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scopes.join(' '),
      'code_challenge': codeChallengeFor(codeVerifier),
      'code_challenge_method': 'S256',
      'state': state,
    });

enum GoogleSignInFailure {
  /// 利用者が許可しなかった（Google の画面で「キャンセル」など）
  denied,

  /// アプリ側でログインを中止した
  cancelled,

  /// 応答が想定外（state の不一致など）。別のログイン操作が紛れ込んだ可能性がある
  invalidResponse,

  /// 通信の失敗や、Google からのエラー応答
  failed,
}

class GoogleSignInException implements Exception {
  const GoogleSignInException(this.failure, [this.detail]);

  final GoogleSignInFailure failure;
  final String? detail;

  @override
  String toString() => 'GoogleSignInException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// ブラウザから戻ってきた URL を調べ、認可コードを取り出す。
String parseAuthorizationCallback(Uri uri, {required String expectedState}) {
  final q = uri.queryParameters;
  if (q['state'] != expectedState) {
    throw const GoogleSignInException(GoogleSignInFailure.invalidResponse, 'state mismatch');
  }
  final error = q['error'];
  if (error != null) {
    throw GoogleSignInException(
      error == 'access_denied' ? GoogleSignInFailure.denied : GoogleSignInFailure.failed,
      error,
    );
  }
  final code = q['code'];
  if (code == null || code.isEmpty) {
    throw const GoogleSignInException(GoogleSignInFailure.invalidResponse, 'no code');
  }
  return code;
}

/// ブラウザでのログイン1回分。PC 内（127.0.0.1）だけで戻り先を待ち受ける。
///
/// googleapis_auth の clientViaUserConsent を使わないのは、待ち受けを途中で止める手段がなく、
/// 利用者がブラウザを閉じると待ち受けが残り続けるため。
class LoopbackSignIn {
  LoopbackSignIn._(this._server, this.redirectUri, this.authorizationUri, this._state, this.codeVerifier,
      this._successPage);

  static Future<LoopbackSignIn> start({required String clientId, required String successPage}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}';
    final verifier = createCodeVerifier();
    final state = createState();
    final session = LoopbackSignIn._(
      server,
      redirectUri,
      buildAuthorizationUri(clientId: clientId, redirectUri: redirectUri, codeVerifier: verifier, state: state),
      state,
      verifier,
      successPage,
    );
    session._listen();
    return session;
  }

  final HttpServer _server;
  final String redirectUri;
  final Uri authorizationUri;
  final String _state;
  final String codeVerifier;
  final String _successPage;
  final _code = Completer<String>();

  /// 認可コード。利用者が許可しなかった・中止した場合は [GoogleSignInException] で終わる。
  Future<String> get code => _code.future;

  void _listen() {
    _server.listen((request) async {
      // ブラウザは favicon なども取りに来るので、戻り先（/）以外は相手にしない
      if (request.uri.path != '/' || _code.isCompleted) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      try {
        _code.complete(parseAuthorizationCallback(request.uri, expectedState: _state));
        _respond(request, _successPage);
      } on GoogleSignInException catch (e) {
        _code.completeError(e);
        _respond(request, '<p>Colophon: ${e.failure.name}</p>');
      }
      await _server.close();
    });
  }

  void _respond(HttpRequest request, String body) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write('<!doctype html><meta charset="utf-8"><title>Colophon</title>'
          '<body style="font-family:sans-serif;margin:3em">$body</body>')
      ..close();
  }

  Future<void> cancel() async {
    if (!_code.isCompleted) _code.completeError(const GoogleSignInException(GoogleSignInFailure.cancelled));
    await _server.close(force: true);
  }
}

// ---------------------------------------------------------------------------
// ログイン情報の保存
// ---------------------------------------------------------------------------

/// ログイン情報（アクセストークンと更新用トークン）と、表示用のメールアドレス。
class GoogleAccount {
  const GoogleAccount({required this.credentials, this.email});

  factory GoogleAccount.fromJson(Map<String, dynamic> json) => GoogleAccount(
        credentials: AccessCredentials.fromJson(json['credentials'] as Map<String, dynamic>),
        email: json['email'] as String?,
      );

  final AccessCredentials credentials;
  final String? email;

  GoogleAccount copyWith({AccessCredentials? credentials}) =>
      GoogleAccount(credentials: credentials ?? this.credentials, email: email);

  Map<String, dynamic> toJson() => {'credentials': credentials.toJson(), 'email': email};
}

abstract class CredentialStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

/// OS の安全な保管場所（Windows: DPAPI で暗号化したファイル、macOS: キーチェーン、Linux: Secret Service）。
class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore()
      : _storage = const FlutterSecureStorage(
          // 署名していない配布版でも動くよう、Keychain Sharing の権限が要らない従来型のキーチェーンを使う
          mOptions: MacOsOptions(usesDataProtectionKeychain: false),
        );

  static const _key = 'google_account';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class MemoryCredentialStore implements CredentialStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> delete() async => value = null;
}

// ---------------------------------------------------------------------------
// ログイン・ログアウト・認証済みクライアント
// ---------------------------------------------------------------------------

/// 画面側から見たログインの窓口。テストでは偽物に差し替える。
abstract class GoogleAuth {
  bool get isConfigured;

  /// 保存してあるログイン情報。なければ null。読めない（壊れている）場合も null。
  Future<GoogleAccount?> restore();

  /// ブラウザでのログインを始める。[GoogleSignInFlow.result] を待つとログイン情報が得られ、保存される。
  Future<GoogleSignInFlow> beginSignIn({required String successPage});

  /// 自動で更新されるアクセストークン付きの HTTP クライアント。更新されたトークンは保存し直す。
  AutoRefreshingAuthClient clientFor(GoogleAccount account);

  /// トークンを Google 側でも無効にし、保存したログイン情報を消す。通信に失敗しても手元の情報は消す。
  Future<void> signOut(GoogleAccount account);
}

class GoogleSignInFlow {
  GoogleSignInFlow({required this.authorizationUri, required this.result, required this.cancel});

  final Uri authorizationUri;
  final Future<GoogleAccount> result;
  final Future<void> Function() cancel;
}

class GoogleAuthService implements GoogleAuth {
  GoogleAuthService(this.config, this.store, {http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final GoogleOAuthConfig config;
  final CredentialStore store;
  final http.Client _http;

  @override
  bool get isConfigured => config.isConfigured;

  @override
  Future<GoogleAccount?> restore() async {
    try {
      final raw = await store.read();
      if (raw == null) return null;
      return GoogleAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // 壊れた・形式の古い保存内容は使わず、ログインし直してもらう
      return null;
    }
  }

  @override
  Future<GoogleSignInFlow> beginSignIn({required String successPage}) async {
    final session = await LoopbackSignIn.start(clientId: config.clientId, successPage: successPage);
    return GoogleSignInFlow(
      authorizationUri: session.authorizationUri,
      result: _complete(session),
      cancel: session.cancel,
    );
  }

  Future<GoogleAccount> _complete(LoopbackSignIn session) async {
    final code = await session.code;
    final AccessCredentials credentials;
    try {
      credentials = await obtainAccessCredentialsViaCodeExchange(
        _http,
        config._clientId,
        code,
        redirectUrl: session.redirectUri,
        codeVerifier: session.codeVerifier,
      );
    } on Object catch (e) {
      throw GoogleSignInException(GoogleSignInFailure.failed, '$e');
    }
    final account = GoogleAccount(credentials: credentials, email: await _fetchEmail(credentials));
    await store.write(jsonEncode(account.toJson()));
    return account;
  }

  /// 表示用。drive.appdata の権限でも Drive の about から取れる。取れなくてもログインは成功とする。
  Future<String?> _fetchEmail(AccessCredentials credentials) async {
    final client = authenticatedClient(_http, credentials, closeUnderlyingClient: false);
    try {
      final about = await drive.DriveApi(client).about.get($fields: 'user(emailAddress)');
      return about.user?.emailAddress;
    } on Object {
      return null;
    } finally {
      client.close();
    }
  }

  @override
  AutoRefreshingAuthClient clientFor(GoogleAccount account) {
    final client = autoRefreshingClient(config._clientId, account.credentials, http.Client());
    client.credentialUpdates.listen((credentials) {
      unawaited(store.write(jsonEncode(account.copyWith(credentials: credentials).toJson())));
    });
    return client;
  }

  @override
  Future<void> signOut(GoogleAccount account) async {
    final token = account.credentials.refreshToken ?? account.credentials.accessToken.data;
    try {
      await _http.post(Uri.https('oauth2.googleapis.com', '/revoke'), body: {'token': token});
    } on Object {
      // 通信できなくてもログアウトは済ませる。トークンは Google アカウントの設定からも無効にできる
    }
    await store.delete();
  }
}

/// クライアントが設定されていないビルド用。同期の欄は「使えません」と表示される。
class UnconfiguredGoogleAuth implements GoogleAuth {
  const UnconfiguredGoogleAuth();

  @override
  bool get isConfigured => false;

  @override
  Future<GoogleAccount?> restore() async => null;

  @override
  Future<GoogleSignInFlow> beginSignIn({required String successPage}) => throw UnsupportedError('not configured');

  @override
  AutoRefreshingAuthClient clientFor(GoogleAccount account) => throw UnsupportedError('not configured');

  @override
  Future<void> signOut(GoogleAccount account) async {}
}
