import 'dart:convert';

import 'package:colophon/services/google_auth.dart';
import 'package:colophon/services/google_auth_mobile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart' as gsi;
import 'package:googleapis_auth/googleapis_auth.dart' show AccessDeniedException;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// スマホ・タブレットの Google ログイン。OS 側（プラグイン）は偽物に差し替える。
void main() {
  late _FakeSignInPlatform platform;
  late MemoryCredentialStore store;
  late List<http.Request> requests;

  setUp(() {
    platform = _FakeSignInPlatform();
    gsi.GoogleSignInPlatform.instance = platform;
    store = MemoryCredentialStore();
    requests = [];
  });

  /// Drive の about（メールアドレス）と、取り消し用の窓口に答える偽の通信路。
  http.Client googleApis({int Function(http.Request)? statusFor}) => MockClient((request) async {
        requests.add(request);
        final status = statusFor?.call(request) ?? 200;
        if (request.url.path.endsWith('/about')) {
          return http.Response(jsonEncode({'user': {'emailAddress': 'reader@example.com'}}), status,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('{}', status, headers: {'content-type': 'application/json'});
      });

  MobileGoogleAuth auth({http.Client Function()? api}) =>
      MobileGoogleAuth(store, httpClient: googleApis(), newApiClient: api ?? googleApis);

  test('ログインでは OS の画面でドライブの許可を求め、メールアドレスだけを保存する（トークンは保存しない）', () async {
    platform.tokens = ['token-1'];
    final flow = await auth().beginSignIn(successPage: '');
    expect(flow.authorizationUri, isNull, reason: 'ブラウザは使わない');
    final account = await flow.result;

    expect(platform.requests.single.promptIfUnauthorized, isTrue);
    expect(platform.requests.single.scopes, googleDriveScopes);
    expect(account.email, 'reader@example.com');
    expect(store.value, isNot(contains('token-1')));
    expect((await auth().restore())?.email, 'reader@example.com');
  });

  for (final (platformName, error) in [
    ('iOS など', const gsi.GoogleSignInException(code: gsi.GoogleSignInExceptionCode.canceled)),
    // Android では、画面を閉じると取り消しの状態コード（16）付きの SDK の例外として届く
    (
      'Android',
      const gsi.GoogleSignInException(
          code: gsi.GoogleSignInExceptionCode.unknownError, description: 'SDK reported an exception: 16: Cancelled'),
    ),
  ]) {
    test('OS の画面を閉じたら「取り消し」で終わり、何も保存しない（$platformName）', () async {
      platform.error = error;
      final flow = await auth().beginSignIn(successPage: '');

      await expectLater(
        flow.result,
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.cancelled)),
      );
      expect(store.value, isNull);
    });
  }

  test('OS の画面での失敗は「失敗」として伝える（取り消しとは区別する）', () async {
    platform.error = const gsi.GoogleSignInException(
        code: gsi.GoogleSignInExceptionCode.unknownError, description: 'SDK reported an exception: 7: NETWORK_ERROR');
    final flow = await auth().beginSignIn(successPage: '');

    await expectLater(
      flow.result,
      throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.failed)),
    );
  });

  test('同期の通信には、ログインしたアカウントを指定し、画面を出さずにもらったトークンを付ける', () async {
    platform.tokens = ['token-1'];
    final client = auth().clientFor(const GoogleAccount(email: 'reader@example.com'));

    await client.get(Uri.parse('https://www.googleapis.com/drive/v3/files'));

    expect(platform.requests.single.promptIfUnauthorized, isFalse);
    expect(platform.requests.single.email, 'reader@example.com', reason: '端末にアカウントが複数あっても取り違えない');
    expect(requests.single.headers['Authorization'], 'Bearer token-1');
  });

  test('もらったトークンは、しばらく使い回す（通信のたびに OS に求めない）', () async {
    platform.tokens = ['token-1', 'token-2'];
    final client = auth().clientFor(const GoogleAccount(email: 'reader@example.com'));

    await client.get(Uri.parse('https://www.googleapis.com/drive/v3/files'));
    await client.get(Uri.parse('https://www.googleapis.com/drive/v3/files'));

    expect(platform.requests, hasLength(1));
    expect(requests.map((r) => r.headers['Authorization']), everyElement('Bearer token-1'));
  });

  test('OS とのやり取りの失敗は、通信の失敗として再試行の対象にする', () async {
    platform.error = const gsi.GoogleSignInException(code: gsi.GoogleSignInExceptionCode.unknownError);
    final client = auth().clientFor(const GoogleAccount());

    await expectLater(
        client.get(Uri.parse('https://www.googleapis.com/drive/v3/files')), throwsA(isA<http.ClientException>()));
  });

  test('設定の誤り（Google Cloud の登録が違うなど）は、待っても直らないのでログインし直しの失敗にする', () async {
    platform.error = const gsi.GoogleSignInException(code: gsi.GoogleSignInExceptionCode.clientConfigurationError);
    final client = auth().clientFor(const GoogleAccount());

    await expectLater(
        client.get(Uri.parse('https://www.googleapis.com/drive/v3/files')), throwsA(isA<AccessDeniedException>()));
  });

  test('トークンの期限が切れていたら（401）、OS の保管分を捨ててもらい直し、同じ内容で1回だけ送り直す', () async {
    platform.tokens = ['old', 'new'];
    final api = googleApis(statusFor: (r) => r.headers['Authorization'] == 'Bearer old' ? 401 : 200);
    final client = auth(api: () => api).clientFor(const GoogleAccount());

    final response = await client.post(Uri.parse('https://www.googleapis.com/upload/drive/v3/files'), body: 'cover');

    expect(response.statusCode, 200);
    expect(platform.cleared, ['old']);
    expect(requests.map((r) => r.headers['Authorization']), ['Bearer old', 'Bearer new']);
    expect(requests.last.body, 'cover', reason: '本文も送り直す');
    expect(requests.last.headers['content-type'], requests.first.headers['content-type']);
  });

  test('許可が取り消されていたら（画面なしではトークンをもらえない）、ログインし直しが要る失敗にする', () async {
    platform.tokens = [];
    final client = auth().clientFor(const GoogleAccount());

    await expectLater(client.get(Uri.parse('https://www.googleapis.com/drive/v3/files')),
        throwsA(isA<AccessDeniedException>()));
    expect(requests, isEmpty);
  });

  test('ログアウトでは許可を Google 側で取り消し、保存したメールアドレスを消す', () async {
    platform.tokens = ['token-1'];
    store.value = jsonEncode(const GoogleAccount(email: 'reader@example.com').toJson());

    await auth().signOut(const GoogleAccount(email: 'reader@example.com'));

    final revoke = requests.single;
    expect(revoke.url.path, '/revoke');
    expect(revoke.bodyFields['token'], 'token-1');
    expect(platform.requests.single.email, 'reader@example.com');
    expect(platform.cleared, ['token-1']);
    expect(platform.signOuts, 1, reason: 'iOS では、OS 側のログインも消さないと次に別のアカウントを選べない');
    expect(store.value, isNull);
  });

  test('iOS 用のクライアント ID を渡すと、それでプラグインを初期化する（Android では渡さない）', () async {
    platform.tokens = ['token-1', 'token-2'];
    await MobileGoogleAuth(store, httpClient: googleApis(), iosClientId: 'ios-123.apps.googleusercontent.com')
        .beginSignIn(successPage: '')
        .then((flow) => flow.result);
    await auth().beginSignIn(successPage: '').then((flow) => flow.result);

    expect(platform.initClientIds, ['ios-123.apps.googleusercontent.com', null]);
  });

  test('ログアウトの取り消しが断られたら（期限切れのトークン）、もらい直して1回だけ送り直す', () async {
    platform.tokens = ['expired', 'fresh'];
    store.value = jsonEncode(const GoogleAccount(email: 'reader@example.com').toJson());
    final rejecting = MobileGoogleAuth(store,
        httpClient: googleApis(statusFor: (r) => r.bodyFields['token'] == 'expired' ? 400 : 200));

    await rejecting.signOut(const GoogleAccount(email: 'reader@example.com'));

    expect(requests.map((r) => r.bodyFields['token']), ['expired', 'fresh']);
    expect(store.value, isNull);
  });
}

/// OS の Google ログインの代わり。[tokens] を先頭から順に渡し、なくなったら「許可なし」（null）を返す。
class _FakeSignInPlatform extends gsi.GoogleSignInPlatform {
  List<String> tokens = [];
  gsi.GoogleSignInException? error;
  final requests = <gsi.AuthorizationRequestDetails>[];
  final cleared = <String>[];
  final initClientIds = <String?>[];
  var signOuts = 0;

  @override
  Future<void> init(gsi.InitParameters params) async => initClientIds.add(params.clientId);

  @override
  Future<gsi.ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    gsi.ClientAuthorizationTokensForScopesParameters params,
  ) async {
    requests.add(params.request);
    if (error != null) throw error!;
    if (tokens.isEmpty) return null;
    return gsi.ClientAuthorizationTokenData(accessToken: tokens.removeAt(0));
  }

  @override
  Future<void> clearAuthorizationToken(gsi.ClearAuthorizationTokenParams params) async =>
      cleared.add(params.accessToken);

  @override
  Future<gsi.AuthenticationResults?>? attemptLightweightAuthentication(
          gsi.AttemptLightweightAuthenticationParameters params) =>
      null;

  @override
  bool supportsAuthenticate() => false;

  @override
  Future<gsi.AuthenticationResults> authenticate(gsi.AuthenticateParameters params) => throw UnimplementedError();

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<gsi.ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
          gsi.ServerAuthorizationTokensForScopesParameters params) async =>
      null;

  @override
  Future<void> signOut(gsi.SignOutParams params) async => signOuts++;

  @override
  Future<void> disconnect(gsi.DisconnectParams params) async {}
}
