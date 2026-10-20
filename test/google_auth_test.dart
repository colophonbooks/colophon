import 'dart:convert';
import 'dart:io';

import 'package:colophon/services/google_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _config = GoogleOAuthConfig(clientId: 'client-123.apps.googleusercontent.com', clientSecret: 'secret');

/// ブラウザの代わりに、戻り先の URL を開く。
Future<HttpClientResponse> _visit(Uri uri) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(uri)).close();
    await response.drain<void>();
    return response;
  } finally {
    client.close();
  }
}

Uri _callback(Uri authorizationUri, Map<String, String> params) {
  final q = authorizationUri.queryParameters;
  return Uri.parse(q['redirect_uri']!).replace(queryParameters: {'state': q['state']!, ...params});
}

AccessCredentials _credentials({String? refreshToken = 'refresh-1'}) => AccessCredentials(
      AccessToken('Bearer', 'access-1', DateTime.utc(2026, 10, 15, 12)),
      refreshToken,
      googleDriveScopes,
    );

void main() {
  group('PKCE と認可 URL', () {
    test('コードチャレンジは RFC 7636 の例と一致する', () {
      expect(codeChallengeFor('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
          'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
    });

    test('コードベリファイアは 64 文字で、使える文字だけからなる', () {
      final v = createCodeVerifier();
      expect(v.length, 64);
      expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(v), isTrue);
      expect(createCodeVerifier(), isNot(v));
    });

    test('認可 URL は drive.appdata の権限だけを求め、PKCE と state を付ける', () {
      final uri = buildAuthorizationUri(
        clientId: _config.clientId,
        redirectUri: 'http://127.0.0.1:5000',
        codeVerifier: 'v' * 64,
        state: 'st',
      );
      expect(uri.host, 'accounts.google.com');
      expect(uri.queryParameters, {
        'client_id': _config.clientId,
        'response_type': 'code',
        'redirect_uri': 'http://127.0.0.1:5000',
        'scope': 'https://www.googleapis.com/auth/drive.appdata',
        'code_challenge': codeChallengeFor('v' * 64),
        'code_challenge_method': 'S256',
        'state': 'st',
      });
    });
  });

  group('戻り先 URL の解析', () {
    Uri back(Map<String, String> q) => Uri.http('127.0.0.1:1', '/', q);

    test('state が一致すれば認可コードを返す', () {
      expect(parseAuthorizationCallback(back({'state': 's', 'code': 'c'}), expectedState: 's'), 'c');
    });

    test('state が違えば想定外の応答として扱う', () {
      expect(
        () => parseAuthorizationCallback(back({'state': 'x', 'code': 'c'}), expectedState: 's'),
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.invalidResponse)),
      );
    });

    test('利用者が拒否した場合は denied、それ以外のエラーは failed', () {
      expect(
        () => parseAuthorizationCallback(back({'state': 's', 'error': 'access_denied'}), expectedState: 's'),
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.denied)),
      );
      expect(
        () => parseAuthorizationCallback(back({'state': 's', 'error': 'server_error'}), expectedState: 's'),
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.failed)),
      );
    });

    test('コードがなければ想定外の応答として扱う', () {
      expect(
        () => parseAuthorizationCallback(back({'state': 's'}), expectedState: 's'),
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.invalidResponse)),
      );
    });
  });

  group('ループバックでの待ち受け', () {
    test('PC 内の 127.0.0.1 だけで待ち受け、戻ってきたコードを受け取る', () async {
      final session = await LoopbackSignIn.start(clientId: _config.clientId, successPage: '<p>done</p>');
      expect(session.redirectUri, startsWith('http://127.0.0.1:'));
      expect(session.authorizationUri.queryParameters['redirect_uri'], session.redirectUri);

      final response = await _visit(_callback(session.authorizationUri, {'code': 'auth-code'}));
      expect(response.statusCode, HttpStatus.ok);
      expect(await session.code, 'auth-code');
    });

    test('戻り先以外へのアクセス（favicon など）は無視して待ち続ける', () async {
      final session = await LoopbackSignIn.start(clientId: _config.clientId, successPage: '');
      final favicon = Uri.parse('${session.redirectUri}/favicon.ico');
      expect((await _visit(favicon)).statusCode, HttpStatus.notFound);

      await _visit(_callback(session.authorizationUri, {'code': 'later'}));
      expect(await session.code, 'later');
    });

    test('中止すると cancelled で終わり、待ち受けも閉じる', () async {
      final session = await LoopbackSignIn.start(clientId: _config.clientId, successPage: '');
      final expectation = expectLater(
        session.code,
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.cancelled)),
      );
      await session.cancel();
      await expectation;
      await expectLater(_visit(Uri.parse(session.redirectUri)), throwsA(isA<SocketException>()));
    });
  });

  group('GoogleAuthService', () {
    late List<http.Request> requests;
    late MemoryCredentialStore store;

    MockClient mock({bool revokeFails = false, bool aboutFails = false}) => MockClient((request) async {
          requests.add(request);
          final url = request.url;
          if (url.host == 'oauth2.googleapis.com' && url.path == '/token') {
            return http.Response(
              jsonEncode({
                'access_token': 'access-1',
                'expires_in': 3600,
                'refresh_token': 'refresh-1',
                'scope': 'https://www.googleapis.com/auth/drive.appdata',
                'token_type': 'Bearer',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (url.path.endsWith('/drive/v3/about')) {
            return aboutFails
                ? http.Response('forbidden', 403)
                : http.Response(jsonEncode({'user': {'emailAddress': 'reader@example.com'}}), 200,
                    headers: {'content-type': 'application/json'});
          }
          if (url.path == '/revoke') {
            if (revokeFails) throw const SocketException('offline');
            return http.Response('', 200);
          }
          return http.Response('not found', 404);
        });

    setUp(() {
      requests = [];
      store = MemoryCredentialStore();
    });

    test('ログインするとコードを交換し、メールアドレスと一緒に保存する', () async {
      final auth = GoogleAuthService(_config, store, httpClient: mock());
      final flow = await auth.beginSignIn(successPage: '');
      await _visit(_callback(flow.authorizationUri!, {'code': 'auth-code'}));
      final account = await flow.result;

      expect(account.email, 'reader@example.com');
      expect(account.credentials!.refreshToken, 'refresh-1');

      final token = requests.firstWhere((r) => r.url.path == '/token');
      expect(token.bodyFields['code'], 'auth-code');
      expect(token.bodyFields['redirect_uri'], flow.authorizationUri!.queryParameters['redirect_uri']);
      expect(codeChallengeFor(token.bodyFields['code_verifier']!),
          flow.authorizationUri!.queryParameters['code_challenge']);

      final restored = await auth.restore();
      expect(restored?.email, 'reader@example.com');
      expect(restored?.credentials?.refreshToken, 'refresh-1');
    });

    test('メールアドレスが取れなくてもログインは成功する', () async {
      final auth = GoogleAuthService(_config, store, httpClient: mock(aboutFails: true));
      final flow = await auth.beginSignIn(successPage: '');
      await _visit(_callback(flow.authorizationUri!, {'code': 'auth-code'}));
      expect((await flow.result).email, isNull);
      expect(store.value, isNotNull);
    });

    test('利用者が拒否すると denied で終わり、何も保存しない', () async {
      final auth = GoogleAuthService(_config, store, httpClient: mock());
      final flow = await auth.beginSignIn(successPage: '');
      final expectation = expectLater(
        flow.result,
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.denied)),
      );
      await _visit(_callback(flow.authorizationUri!, {'error': 'access_denied'}));
      await expectation;
      expect(store.value, isNull);
    });

    test('トークンのない保存内容（スマホでの形式）は、パソコンではログインしていない扱いにする', () async {
      store.value = jsonEncode(const GoogleAccount(email: 'a@example.com').toJson());
      expect(await GoogleAuthService(_config, store, httpClient: mock()).restore(), isNull);
    });

    test('保存内容が壊れていればログインしていない扱いにする', () async {
      store.value = '{broken';
      expect(await GoogleAuthService(_config, store, httpClient: mock()).restore(), isNull);
    });

    test('ログアウトはトークンを無効にして保存内容を消す。通信に失敗しても消す', () async {
      for (final fails in [false, true]) {
        requests.clear();
        final account = GoogleAccount(credentials: _credentials(), email: 'a@example.com');
        store.value = jsonEncode(account.toJson());
        await GoogleAuthService(_config, store, httpClient: mock(revokeFails: fails)).signOut(account);
        expect(store.value, isNull, reason: 'revokeFails=$fails');
        final revoke = requests.singleWhere((r) => r.url.path == '/revoke');
        expect(revoke.bodyFields['token'], 'refresh-1');
      }
    });

    test('保存形式は往復しても変わらない', () {
      final account = GoogleAccount(credentials: _credentials(), email: 'a@example.com');
      final back = GoogleAccount.fromJson(jsonDecode(jsonEncode(account.toJson())) as Map<String, dynamic>);
      expect(back.email, account.email);
      expect(back.credentials!.accessToken.data, 'access-1');
      expect(back.credentials!.accessToken.expiry, account.credentials!.accessToken.expiry);
      expect(back.credentials!.refreshToken, 'refresh-1');
      expect(back.credentials!.scopes, googleDriveScopes);
    });
  });

  test('クライアント ID がなければ設定されていない扱い', () {
    expect(const GoogleOAuthConfig(clientId: '', clientSecret: '').isConfigured, isFalse);
    expect(_config.isConfigured, isTrue);
  });
}
