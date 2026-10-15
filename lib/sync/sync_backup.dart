import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/book_repository.dart';
import '../services/backup.dart';

/// 初めての同期の前に取るバックアップ（エクスポートと同じ ZIP 形式。インポートで戻せる）を書き出す。
/// [keep] 個を超えた古いものは消す。書き出したファイルを返す。
Future<File> writeSyncBackup(BookRepository repository, Directory dir, {required DateTime now, int keep = 3}) async {
  await dir.create(recursive: true);
  final stamp = now.toLocal().toIso8601String().substring(0, 19).replaceAll(RegExp('[-:]'), '').replaceAll('T', '-');
  final file = File(p.join(dir.path, 'colophon-before-first-sync-$stamp.zip'));
  await file.writeAsBytes(await exportZipInBackground(repository.getAllBooks()), flush: true);

  final backups = dir
      .listSync()
      .whereType<File>()
      .where((f) => p.basename(f.path).startsWith('colophon-before-first-sync-') && f.path.endsWith('.zip'))
      .toList()
    ..sort((a, b) => b.path.compareTo(a.path));
  for (final old in backups.skip(keep)) {
    await old.delete();
  }
  return file;
}
