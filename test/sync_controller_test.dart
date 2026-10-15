
import 'package:colophon/l10n/app_localizations.dart';
import 'package:colophon/services/google_auth.dart';
import 'package:colophon/state/sync_controller.dart';
import 'package:colophon/ui/sync_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'sync_fakes.dart';

GoogleAccount _account([String? email = 'reader@example.com']) => fakeAccount(email);

Future<void> _settle(SyncController c) => settle(c);

void main() {
  group('SyncController', () {
    test('クライアントが設定されていなければ unavailable', () {
      expect(SyncController(const UnconfiguredGoogleAuth()).state, SyncAuthState.unavailable);
    });

    test('保存したログイン情報があれば signedIn、なければ signedOut で始まる', () async {
      final a = SyncController(FakeGoogleAuth(stored: _account()));
      await _settle(a);
      expect(a.state, SyncAuthState.signedIn);
      expect(a.accountEmail, 'reader@example.com');

      final b = SyncController(FakeGoogleAuth());
      await _settle(b);
      expect(b.state, SyncAuthState.signedOut);
    });

    test('ログイン中はブラウザ用の URL を持ち、完了すると signedIn になる', () async {
      final auth = FakeGoogleAuth();
      final c = SyncController(auth);
      await _settle(c);

      Uri? opened;
      final signIn = c.signIn(successPage: '', openBrowser: (uri) async => opened = uri);
      await Future<void>.delayed(Duration.zero);
      expect(c.state, SyncAuthState.signingIn);
      expect(c.pendingAuthorizationUri, opened);

      auth.pending!.complete(_account('new@example.com'));
      await signIn;
      expect(c.state, SyncAuthState.signedIn);
      expect(c.accountEmail, 'new@example.com');
      expect(c.pendingAuthorizationUri, isNull);
    });

    test('ブラウザを開けなくても待ち続ける', () async {
      final auth = FakeGoogleAuth();
      final c = SyncController(auth);
      await _settle(c);

      final signIn = c.signIn(successPage: '', openBrowser: (_) async => throw Exception('no browser'));
      await Future<void>.delayed(Duration.zero);
      expect(c.state, SyncAuthState.signingIn);
      auth.pending!.complete(_account());
      await signIn;
      expect(c.state, SyncAuthState.signedIn);
    });

    test('中止・拒否するとログアウト状態に戻り、例外で理由を知らせる', () async {
      final auth = FakeGoogleAuth();
      final c = SyncController(auth);
      await _settle(c);

      final cancelled = expectLater(
        c.signIn(successPage: '', openBrowser: (_) async {}),
        throwsA(isA<GoogleSignInException>().having((e) => e.failure, 'failure', GoogleSignInFailure.cancelled)),
      );
      await Future<void>.delayed(Duration.zero);
      await c.cancelSignIn();
      await cancelled;
      expect(c.state, SyncAuthState.signedOut);

      final denied = c.signIn(successPage: '', openBrowser: (_) async {});
      await Future<void>.delayed(Duration.zero);
      auth.pending!.completeError(const GoogleSignInException(GoogleSignInFailure.denied));
      await expectLater(denied, throwsA(isA<GoogleSignInException>()));
      expect(c.state, SyncAuthState.signedOut);
    });

    test('ログアウトするとログイン情報を手放す', () async {
      final account = _account();
      final auth = FakeGoogleAuth(stored: account);
      final c = SyncController(auth);
      await _settle(c);

      await c.signOut();
      expect(c.state, SyncAuthState.signedOut);
      expect(c.accountEmail, isNull);
      expect(auth.signedOut, [account]);
    });
  });

  group('設定画面の同期欄', () {
    Future<void> pump(WidgetTester tester, SyncController sync) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider.value(
          value: sync,
          child: const Scaffold(body: SyncSettingsSection()),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('設定のないビルドでは使えない旨を表示し、ボタンを出さない', (tester) async {
      await pump(tester, SyncController(const UnconfiguredGoogleAuth()));
      expect(find.textContaining('このビルドでは同期を使えません'), findsOneWidget);
      expect(find.text('ログイン'), findsNothing);
    });

    testWidgets('ログアウト中はログインボタン、ログイン中はアカウントとログアウトボタン', (tester) async {
      final out = SyncController(FakeGoogleAuth());
      await pump(tester, out);
      expect(find.text('ログイン'), findsOneWidget);

      final inn = SyncController(FakeGoogleAuth(stored: _account()));
      await pump(tester, inn);
      expect(find.text('ログイン中: reader@example.com'), findsOneWidget);
      expect(find.text('ログアウト'), findsOneWidget);
    });

    testWidgets('ログアウトは確認してから行う', (tester) async {
      final auth = FakeGoogleAuth(stored: _account());
      final sync = SyncController(auth);
      await pump(tester, sync);

      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();
      expect(find.text('ログアウトしますか？'), findsOneWidget);
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(sync.state, SyncAuthState.signedIn);

      await tester.tap(find.text('ログアウト'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'ログアウト').last);
      await tester.pumpAndSettle();
      expect(sync.state, SyncAuthState.signedOut);
      expect(find.text('ログイン'), findsOneWidget);
    });
  });
}
