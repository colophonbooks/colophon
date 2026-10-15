import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:colophon/data/book_repository.dart';
import 'package:colophon/services/google_auth.dart';
import 'package:colophon/state/sync_controller.dart';
import 'package:colophon/sync/drive_store.dart';
import 'package:colophon/sync/sync_engine.dart';
import 'package:colophon/sync/sync_state.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

GoogleAccount fakeAccount([String? email = 'reader@example.com']) => GoogleAccount(
      credentials: AccessCredentials(
        AccessToken('Bearer', 'access', DateTime.utc(2099)),
        'refresh',
        googleDriveScopes,
      ),
      email: email,
    );

/// ブラウザを使わずにログイン状態を作る、偽の Google ログイン。
class FakeGoogleAuth implements GoogleAuth {
  FakeGoogleAuth({this.stored});

  GoogleAccount? stored;
  Completer<GoogleAccount>? pending;
  bool cancelled = false;
  final signedOut = <GoogleAccount>[];

  @override
  bool get isConfigured => true;

  @override
  Future<GoogleAccount?> restore() async => stored;

  @override
  Future<GoogleSignInFlow> beginSignIn({required String successPage}) async {
    pending = Completer<GoogleAccount>();
    return GoogleSignInFlow(
      authorizationUri: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth?state=x'),
      result: pending!.future,
      cancel: () async {
        cancelled = true;
        if (!pending!.isCompleted) {
          pending!.completeError(const GoogleSignInException(GoogleSignInFailure.cancelled));
        }
      },
    );
  }

  /// 同期エンジンはメモリ上の Drive を使うので、通信しないクライアントを返す。
  @override
  AutoRefreshingAuthClient clientFor(GoogleAccount account) =>
      autoRefreshingClient(ClientId('test'), account.credentials, MockClient((_) async => http.Response('', 200)));

  @override
  Future<void> signOut(GoogleAccount account) async {
    signedOut.add(account);
    stored = null;
  }
}

/// メモリ上の Drive で同期する SyncController。
SyncController fakeSyncController(
  BookRepository repo, {
  required MemoryDriveStore drive,
  GoogleAccount? account,
  SyncStateStore? state,
  Directory? backupDirectory,
}) {
  final store = state ?? MemorySyncStateStore();
  return SyncController(
    FakeGoogleAuth(stored: account),
    stateStore: store,
    backupDirectory: backupDirectory,
    engineFactory: (_) => SyncEngine(
      repository: repo,
      drive: drive,
      state: store,
      makeThumbnail: (bytes) async => Uint8List.fromList([0]),
    ),
  );
}

/// 保存したログイン情報の読み込みが終わるまで待つ。
Future<void> settle(SyncController c) async {
  while (c.state == SyncAuthState.loading) {
    await Future<void>.delayed(Duration.zero);
  }
}
