import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/book_repository.dart';
import 'services/google_auth.dart';
import 'state/settings_controller.dart';
import 'state/sync_controller.dart';
import 'sync/drive_store.dart';
import 'sync/sync_backup.dart';
import 'sync/sync_engine.dart';
import 'sync/sync_state.dart';

/// 開発用: 本棚・設定・ログイン情報を、普段の版と分けて置く場所（--dart-define で渡す）。
/// 試験版が普段の本棚を開いて DB を新しい版へ移行し、配布中の版で開けなくなるのを防ぐ。
/// フォルダ名ごとに設定とログイン情報も分けるので、フォルダを変えて2つ動かせば2台の同期を試せる。
const _devDataDir = String.fromEnvironment('COLOPHON_DATA_DIR');
final _devName = _devDataDir.isEmpty ? '' : p.basename(_devDataDir);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_devDataDir.isNotEmpty) SharedPreferences.setPrefix('colophon-dev-$_devName.');
  final prefs = await SharedPreferences.getInstance();
  final dir = _devDataDir.isNotEmpty ? Directory(_devDataDir) : await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final dbPath = p.join(dir.path, 'colophon.db');

  try {
    final db = openAppDatabase(dbPath);
    const oauth = GoogleOAuthConfig.fromEnvironment();
    final repository = BookRepository(db);
    final syncState = FileSyncStateStore(File(p.join(dir.path, 'sync-state.json')));
    final syncBackups = Directory(p.join(dir.path, 'sync-backups'));
    runApp(ColophonApp(
      settings: SettingsController(prefs),
      repository: repository,
      sync: SyncController(
        oauth.isConfigured
            ? GoogleAuthService(
                oauth, SecureCredentialStore(key: _devDataDir.isEmpty ? 'google_account' : 'google_account_dev_$_devName'))
            : const UnconfiguredGoogleAuth(),
        stateStore: syncState,
        backupDirectory: syncBackups,
        engineFactory: (client) => SyncEngine(
          repository: repository,
          drive: GoogleDriveStore(client),
          state: syncState,
          backupBeforeFirstSync: () async {
            await writeSyncBackup(repository, syncBackups, now: DateTime.now());
          },
        ),
      ),
    ));
  } on SqliteException catch (e) {
    runApp(_StartupErrorApp('Could not open the library database.\n$dbPath\n\n$e'));
  } on NewerSchemaException {
    // 新しいバージョンで作られたDBを壊さないよう、開かずに案内だけ出す
    runApp(const _StartupErrorApp(
      'This library was saved by a newer version of Colophon. Please update the app.',
    ));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Colophon',
        home: Scaffold(
          body: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
          ),
        ),
      );
}
