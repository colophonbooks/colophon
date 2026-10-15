import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../services/backup.dart';
import '../state/library_controller.dart';
import '../state/settings_controller.dart';
import 'common.dart';

enum _ExportFormat { text, zip, sqlite }

Future<void> runExport(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final repo = context.read<BookRepository>();
  if (repo.countBooks() == 0) {
    showMessage(context, l.exportEmpty);
    return;
  }

  final settings = context.read<SettingsController>();
  final format = await showDialog<_ExportFormat>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SimpleDialog(
        title: Text(l.exportTitle),
        children: [
          for (final (f, icon, title, desc) in [
            (_ExportFormat.text, Icons.description_outlined, l.exportText, l.exportTextDesc),
            (_ExportFormat.zip, Icons.folder_zip_outlined, l.exportZip, l.exportZipDesc),
            (_ExportFormat.sqlite, Icons.storage_outlined, l.exportSqlite, l.exportSqliteDesc),
          ]) ...[
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              subtitle: Text(desc),
              onTap: () => Navigator.pop(context, f),
            ),
            if (f == _ExportFormat.text)
              CheckboxListTile(
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(l.exportTextIncludeCovers),
                value: settings.exportTextWithCovers,
                onChanged: (v) => settings.setExportTextWithCovers(v ?? false),
              ),
          ],
        ],
      ),
    ),
  );
  if (format == null || !context.mounted) return;
  final withCovers = format == _ExportFormat.text && settings.exportTextWithCovers;

  try {
    final now = DateTime.now();
    final stamp = '${LocalDate.fromDateTime(now).toIso().replaceAll('-', '')}'
        '-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    // 書影を含む形式は時間がかかるため、どの形式も処理中の表示を出しながら作る
    final (bytes, ext, mime) = await runWithProgress(context, () async {
      return switch (format) {
        _ExportFormat.text when withCovers => (
            await exportTextWithCovers(repo.getAllBooks(), l, now: now),
            'zip',
            'application/zip',
          ),
        _ExportFormat.text => (
            utf8.encode(exportText(repo.getAllBooks(withImages: false), l, now: now)),
            'txt',
            'text/plain',
          ),
        _ExportFormat.zip => (await exportZipInBackground(repo.getAllBooks()), 'zip', 'application/zip'),
        _ExportFormat.sqlite => (exportSqlite(repo.db), 'sqlite', 'application/vnd.sqlite3'),
      };
    });    final saved = await FilePicker.saveFile(
      dialogTitle: l.exportTitle,
      fileName: 'colophon-$stamp.$ext',
      bytes: bytes,
      mimeType: mime,
      type: FileType.custom,
      allowedExtensions: [ext],
    );
    if (saved != null && context.mounted) showMessage(context, l.exportDone);
  } catch (_) {
    if (context.mounted) showMessage(context, l.exportFailed);
  }
}

Future<void> runImport(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final repo = context.read<BookRepository>();
  final library = context.read<LibraryController>();

  final file = await FilePicker.pickFile(
    dialogTitle: l.importTitle,
    type: FileType.custom,
    allowedExtensions: ['zip', 'sqlite', 'sqlite3', 'db'],
  );
  if (file == null || !context.mounted) return;

  final List<Book> books;
  try {
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    books = await runWithProgress(context, () => readBackup(bytes));
  } on InvalidBackupException {
    if (context.mounted) showMessage(context, l.importInvalidFile);
    return;
  } on NewerBackupException {
    if (context.mounted) showMessage(context, l.importNewerVersion);
    return;
  } catch (_) {
    if (context.mounted) showMessage(context, l.importFailed);
    return;
  }
  if (!context.mounted) return;

  final mode = await showDialog<ImportMode>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l.importTitle),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(l.importFound(books.length)),
        ),
        ListTile(
          enabled: books.isNotEmpty,
          leading: const Icon(Icons.library_add_outlined),
          title: Text(l.importModeMerge),
          subtitle: Text(l.importModeMergeDesc),
          onTap: () => Navigator.pop(context, ImportMode.merge),
        ),
        ListTile(
          // 0冊のファイルで置き換えると全削除と同じになるため選べなくする
          enabled: books.isNotEmpty,
          leading: const Icon(Icons.restore_page_outlined),
          title: Text(l.importModeReplace),
          subtitle: Text(l.importModeReplaceDesc),
          onTap: () => Navigator.pop(context, ImportMode.replace),
        ),
      ],
    ),
  );
  if (mode == null || !context.mounted) return;

  final current = repo.countBooks();
  if (mode == ImportMode.replace && current > 0) {
    final ok = await confirmDialog(
      context,
      message: l.importReplaceConfirm(current),
      confirmLabel: l.importModeReplace,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
  }

  try {
    final result = applyImport(repo, books, mode);
    library.reload();
    if (context.mounted) showMessage(context, l.importDone(result.added, result.skipped));
  } catch (_) {
    if (context.mounted) showMessage(context, l.importFailed);
  }
}
