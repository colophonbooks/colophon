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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final dbPath = p.join(dir.path, 'colophon.db');

  try {
    final db = openAppDatabase(dbPath);
    const oauth = GoogleOAuthConfig.fromEnvironment();
    final repository = BookRepository(db);
    final syncState = PrefsSyncStateStore(prefs);
    final syncBackups = Directory(p.join(dir.path, 'sync-backups'));
    runApp(ColophonApp(
      settings: SettingsController(prefs),
      repository: repository,
      sync: SyncController(
        oauth.isConfigured ? GoogleAuthService(oauth, SecureCredentialStore()) : const UnconfiguredGoogleAuth(),
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
