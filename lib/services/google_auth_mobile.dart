import 'dart:async';
import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart' as gsi_platform;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' show AccessDeniedException;
import 'package:http/http.dart' as http;

import 'google_auth.dart';

/// スマホ・タブレット（Android・iOS）での Google ログイン。
///
/// OS のアカウント選択・許可の画面を使い、トークンは OS が管理する（アプリには保存しない）。
/// Android は、アプリの識別子と署名の指紋で Google Cloud に登録したアプリだと見分けられるので、
/// アプリにクライアント ID を持たせなくてよい。ログイン（本人確認）の段階は使わず、
/// ドライブの許可だけを求める（本人確認にはウェブ用のクライアント ID が別に要るため）。
class MobileGoogleAuth implements GoogleAuth {
  MobileGoogleAuth(
    this.store, {
    this.isConfigured = true,
    http.Client? httpClient,
    http.Client Function()? newApiClient,
  })  : _http = httpClient ?? http.Client(),
        _newApiClient = newApiClient ?? http.Client.new;

  /// 表示用のメールアドレスだけを保存する（保存してあれば、ログインしている）。
  final CredentialStore store;

  @override
  final bool isConfigured;

  final http.Client _http;

  /// 同期でドライブを呼ぶときの通信路（テストで差し替える）。
  final http.Client Function() _newApiClient;

  late final _os = _OsAuthorization();

  @override
  Future<GoogleAccount?> restore() async {
    try {
      final raw = await store.read();
      if (raw == null) return null;
      return GoogleAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // 壊れた保存内容は使わず、ログインし直してもらう
      return null;
    }
  }

  @override
  Future<GoogleSignInFlow> beginSignIn({required String successPage}) async =>
      // OS の画面は、アプリの側から閉じられない（利用者が閉じれば、取り消しとして終わる）
      GoogleSignInFlow(result: _signInNow(), cancel: () async {});

  Future<GoogleAccount> _signInNow() async {
    final String token;
    try {
      token = await _os.token(email: null, prompt: true);
    } on gsi.GoogleSignInException catch (e) {
      throw GoogleSignInException(
        _isCancel(e) ? GoogleSignInFailure.cancelled : GoogleSignInFailure.failed,
        '${e.code.name} ${e.description ?? ''}',
      );
    } on Object catch (e) {
      throw GoogleSignInException(GoogleSignInFailure.failed, '$e');
    }
    final account = GoogleAccount(email: await _fetchEmail(token));
    await store.write(jsonEncode(account.toJson()));
    return account;
  }

  /// 表示用。drive.appdata の権限でも Drive の about から取れる。取れなくてもログインは成功とする。
  Future<String?> _fetchEmail(String token) async {
    try {
      final about = await drive.DriveApi(_BearerClient(_http, token)).about.get($fields: 'user(emailAddress)');
      return about.user?.emailAddress;
    } on Object {
      return null;
    }
  }

  @override
  http.Client clientFor(GoogleAccount account) => _OsTokenClient(_os, account.email, _newApiClient());

  @override
  Future<void> signOut(GoogleAccount account) async {
    // 許可そのものを Google 側で取り消す。OS の仕組みでの取り消しは、本人確認からログインした
    // アカウントにしか効かないため、パソコンと同じく取り消し用の窓口に送る。
    // 許可が残ると、次のログインで別のアカウントを選べないことがあるので、OS が期限切れの
    // トークンを渡してきて断られたら、捨ててもらい直して1回だけ送り直す
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final token = await _os.token(email: account.email, prompt: false);
        final response = await _http.post(Uri.https('oauth2.googleapis.com', '/revoke'), body: {'token': token});
        await _os.clear(token);
        if (response.statusCode == 200) break;
      } on Object {
        // 通信できない・許可がもうない。ログアウトは済ませる（許可は Google アカウントの設定からも取り消せる）
        break;
      }
    }
    await store.delete();
  }
}

/// 利用者が OS の画面を閉じた（選ばなかった）か。
/// Android では、画面を閉じても「取り消し」ではなく、SDK の例外（取り消しの状態コード 16）として届く。
bool _isCancel(gsi.GoogleSignInException e) =>
    e.code == gsi.GoogleSignInExceptionCode.canceled ||
    (e.code == gsi.GoogleSignInExceptionCode.unknownError && (e.description ?? '').contains(': 16:'));

/// OS からトークンをもらう窓口。
class _OsAuthorization {
  Future<void>? _initialized;

  /// プラグインの初期化は1回だけ（2回目はエラーになる）。失敗したら、次に呼ばれたときにやり直す。
  Future<void> _init() => _initialized ??= gsi.GoogleSignIn.instance.initialize().catchError((Object e) {
        _initialized = null;
        throw e;
      });

  /// [email] のアカウントのトークン。[prompt] なら、必要に応じて OS の画面を出す。
  /// 画面を出さずにもらえなければ [AccessDeniedException]。
  ///
  /// 端末に Google アカウントが複数あると、アカウントを指定しない限りどれのトークンが返るか
  /// 決まらない（別のアカウントのドライブと黙って同期しかねない）ため、ログインしたアカウントを指定する。
  /// アプリ向けの窓口にはアカウントを指定する方法がない（本人確認をした場合に限られる）ので、
  /// プラグインの下の層を直接呼ぶ。
  Future<String> token({required String? email, required bool prompt}) async {
    await _init();
    final data = await gsi_platform.GoogleSignInPlatform.instance.clientAuthorizationTokensForScopes(
      gsi_platform.ClientAuthorizationTokensForScopesParameters(
        request: gsi_platform.AuthorizationRequestDetails(
          scopes: googleDriveScopes,
          userId: null,
          email: email,
          promptIfUnauthorized: prompt,
        ),
      ),
    );
    if (data == null) throw AccessDeniedException('Google Drive access is not authorized for this account');
    return data.accessToken;
  }

  /// 期限切れなどで使えないトークンを、OS の保管分から捨てる。失敗しても、もらい直しは続ける。
  Future<void> clear(String token) async {
    try {
      await gsi_platform.GoogleSignInPlatform.instance
          .clearAuthorizationToken(gsi_platform.ClearAuthorizationTokenParams(accessToken: token));
    } on Object {
      // 捨てられなくても、次にもらうトークンで試す
    }
  }
}

/// 決まったトークンを付けて送るクライアント（ログイン直後にメールアドレスを調べるため）。
class _BearerClient extends http.BaseClient {
  _BearerClient(this._inner, this._token);

  final http.Client _inner;
  final String _token;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}

/// OS からトークンをもらって付けて送るクライアント。
///
/// トークンには有効期限（およそ1時間）があるが、OS からは期限が分からない。そこで一定時間ごとに
/// もらい直し、それでも期限切れ（401）が返ったら、OS の保管分を捨ててもらい直して1回だけ送り直す。
class _OsTokenClient extends http.BaseClient {
  _OsTokenClient(this._os, this._email, this._inner);

  final _OsAuthorization _os;

  /// ログインしたアカウント。取れなかった場合は null（アカウントを指定せずにもらう）。
  final String? _email;
  final http.Client _inner;

  /// もらったトークンを使い回す時間。期限（およそ1時間）より短くしておく。
  static const _reuseFor = Duration(minutes: 30);

  String? _token;
  DateTime? _tokenAt;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 送り直すときに本文を読み直せないため、先にすべて読んでおく（Drive に送るのは書影でも数 MB まで）
    final body = await request.finalize().toBytes();
    var token = await _currentToken();
    final response = await _inner.send(_copy(request, body, token));
    if (response.statusCode != 401) return response;
    await response.stream.drain<void>();
    await _os.clear(token);
    _token = null;
    token = await _currentToken();
    return _inner.send(_copy(request, body, token));
  }

  Future<String> _currentToken() async {
    final at = _tokenAt;
    final cached = _token;
    if (cached != null && at != null && DateTime.now().difference(at) < _reuseFor) return cached;
    final String token;
    try {
      token = await _os.token(email: _email, prompt: false);
    } on gsi.GoogleSignInException catch (e) {
      final detail = '${e.code.name} ${e.description ?? ''}';
      // 設定の誤り（Google Cloud に登録した署名の指紋が違うなど）は、待っても直らないので再試行しない
      if (e.code == gsi.GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == gsi.GoogleSignInExceptionCode.providerConfigurationError) {
        throw AccessDeniedException(detail);
      }
      // OS とのやり取りに失敗した（通信できないなど）。時間をおいて再試行する
      throw http.ClientException(detail);
    }
    _tokenAt = DateTime.now();
    return _token = token;
  }

  static http.Request _copy(http.BaseRequest original, List<int> body, String token) {
    final copy = http.Request(original.method, original.url)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection
      ..headers.addAll(original.headers)
      ..bodyBytes = body;
    copy.headers['Authorization'] = 'Bearer $token';
    return copy;
  }

  @override
  void close() => _inner.close();
}
