import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../data/book_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../state/library_controller.dart';
import '../state/settings_controller.dart';
import '../state/sync_controller.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_plan.dart';
import 'app_theme.dart';
import 'common.dart';
import 'data_transfer.dart';
import 'sync_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();
    final current = settings.locale?.languageCode;
    final sectionStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        );

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(title, style: sectionStyle),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                section(l.settingsLanguage),
                for (final lang in supportedLanguages)
                  ListTile(
                    title: Text(lang.name),
                    selected: lang.code == current,
                    trailing: lang.code == current ? const Icon(Icons.check) : null,
                    onTap: () => settings.setLanguage(lang.code),
                  ),
                section(l.settingsAppearance),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.settingsColorTheme, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final id in ColorThemeId.values)
                            _ThemeSwatch(
                              id: id,
                              selected: id == settings.colorTheme,
                              onTap: () => settings.setColorTheme(id),
                            ),
                        ],
                      ),
                      if (settings.colorTheme == ColorThemeId.universal) ...[
                        const SizedBox(height: 8),
                        Text(l.themeUniversalDesc, style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 20),
                      Text(l.settingsBrightness, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: const Icon(Icons.brightness_auto),
                            label: Text(l.brightnessSystem),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: const Icon(Icons.light_mode),
                            label: Text(l.brightnessLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: const Icon(Icons.dark_mode),
                            label: Text(l.brightnessDark),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (s) => settings.setThemeMode(s.single),
                      ),
                    ],
                  ),
                ),
                section(l.settingsCover),
                SwitchListTile(
                  title: Text(l.settingsAutoResize),
                  subtitle: Text(l.settingsAutoResizeDesc),
                  value: settings.autoResize,
                  onChanged: settings.setAutoResize,
                ),
                section(l.settingsSync),
                const SyncSettingsSection(),
                section(l.settingsData),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                  title: Text(l.deleteAllData, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  subtitle: Text(l.deleteAllDataDesc),
                  onTap: () => deleteAllDataFlow(context),
                ),
                section(l.settingsAbout),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) => ListTile(
                    leading: const Icon(Icons.auto_stories_outlined),
                    title: const Text('Colophon'),
                    subtitle: snapshot.hasData ? Text(l.settingsVersion(snapshot.data!.version)) : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.travel_explore),
                  title: Text(l.settingsDataSources),
                  subtitle: Text(l.settingsDataSourcesDesc),
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(l.settingsLicenses),
                  onTap: () => showLicensePage(context: context, applicationName: 'Colophon'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String themeName(AppLocalizations l, ColorThemeId id) => switch (id) {
      ColorThemeId.leather => l.themeLeather,
      ColorThemeId.forest => l.themeForest,
      ColorThemeId.ocean => l.themeOcean,
      ColorThemeId.rose => l.themeRose,
      ColorThemeId.monochrome => l.themeMonochrome,
      ColorThemeId.universal => l.themeUniversal,
    };

/// テーマの見本。いまの明るさでの主な色と、ステータスの色を並べて見せる。
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.id, required this.selected, required this.onTap});

  final ColorThemeId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = Theme.of(context);
    final brightness = current.brightness;
    final scheme = colorSchemeFor(id, brightness);
    final status = statusColorsFor(id, brightness, scheme);
    return Semantics(
      selected: selected,
      button: true,
      label: themeName(l, id),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? current.colorScheme.primary : current.colorScheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 36,
                color: scheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: selected ? Icon(Icons.check_circle, color: scheme.onPrimary, size: 20) : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                child: Row(
                  children: [
                    for (final s in ReadingStatus.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: status.of(s).background,
                          child: Icon(statusIcon(s), size: 12, color: status.of(s).foreground),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Text(
                  themeName(l, id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: current.textTheme.labelLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DeleteStep { exportFirst, proceed }

/// 「すべてのデータを削除」。取り消せない操作なので、案内（先にエクスポートできる）と
/// 最終確認（理解したことのチェックが必要）の二段階で確認する。
enum _DeleteScope { thisComputer, everywhere }

/// クラウドとほかのパソコンからも消すため、すべての書籍に削除済みの印を付けて同期する。
///
/// 先に一度同期して、ほかのパソコンで足された書籍もこのパソコンに集めてから印を付ける
/// （このパソコンが知らない書籍は消せないため）。最初の同期に失敗したら何も消さない。
/// 成功すれば true。失敗した理由はスナックバーで知らせる。
Future<bool> _deleteEverywhere(
    BuildContext context, SyncController sync, BookRepository repo, LibraryController library) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(children: [
        const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(width: 20),
        Expanded(child: Text(l.deleteEverywhereProgress)),
      ]),
    ),
  );
  // 送信まで済んだ（クラウドにも届いた）ときだけ成功とする。読めない記録があると送信を見合わせるため
  bool delivered(SyncResult? r, {required bool mustUpload}) =>
      r is SyncDone && !r.remoteUnreadable && (r.uploaded || !mustUpload);
  try {
    if (!delivered(await sync.syncNow(firstSync: FirstSyncMode.merge), mustUpload: false)) {
      messenger.showSnackBar(SnackBar(content: Text(l.deleteEverywhereSyncFailed)));
      return false;
    }
    final hadBooks = repo.countBooks() > 0;
    repo.deleteAllBooks(afterEachUpdate: true);
    library.reload();
    if (!delivered(await sync.syncNow(purgeUnusedCovers: true), mustUpload: hadBooks)) {
      messenger.showSnackBar(SnackBar(content: Text(l.deleteEverywherePartial)));
      return false;
    }
    return true;
  } finally {
    navigator.pop();
  }
}

Future<void> deleteAllDataFlow(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final repo = context.read<BookRepository>();
  ButtonStyle destructive(BuildContext context) => FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      );

  final step = await showDialog<_DeleteStep>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.deleteAllConfirmTitle),
      content: Text(l.deleteAllConfirmBody(repo.countBooks())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _DeleteStep.exportFirst), child: Text(l.exportFirst)),
        FilledButton(
          style: destructive(context),
          onPressed: () => Navigator.pop(context, _DeleteStep.proceed),
          child: Text(l.proceedToDelete),
        ),
      ],
    ),
  );
  if (step == null || !context.mounted) return;
  if (step == _DeleteStep.exportFirst) {
    await runExport(context);
    return;
  }

  final sync = context.read<SyncController>();
  final syncOn = sync.state == SyncAuthState.signedIn;
  var scope = _DeleteScope.thisComputer;
  var acknowledged = false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l.deleteAllFinalTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 同期しているときは、ほかのパソコンにも伝えるかを選んでもらう
            if (syncOn) ...[
              Text(l.deleteScopeTitle, style: Theme.of(context).textTheme.titleSmall),
              RadioGroup<_DeleteScope>(
                groupValue: scope,
                onChanged: (v) => setDialogState(() => scope = v ?? scope),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _DeleteScope.thisComputer,
                      title: Text(l.deleteScopeThisPc),
                      subtitle: Text(l.deleteScopeThisPcDesc),
                    ),
                    RadioListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _DeleteScope.everywhere,
                      title: Text(l.deleteScopeEverywhere),
                      subtitle: Text(l.deleteScopeEverywhereDesc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: acknowledged,
              title: Text(l.deleteAllAcknowledge),
              onChanged: (v) => setDialogState(() => acknowledged = v ?? false),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(
            style: destructive(context),
            onPressed: acknowledged ? () => Navigator.pop(context, true) : null,
            child: Text(l.deleteAllButton),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final settings = context.read<SettingsController>();
  final library = context.read<LibraryController>();
  final messenger = ScaffoldMessenger.of(context);
  // 実行中の同期が終わってから進める（途中の同期が、消した後に書き込まないように）
  await sync.whenIdle();
  if (!context.mounted) return;
  if (syncOn && scope == _DeleteScope.everywhere) {
    if (!await _deleteEverywhere(context, sync, repo, library) || !context.mounted) return;
  }
  // どちらの範囲でも、このパソコンの同期はオフにする（消したあとにクラウドから取り戻さないように）
  if (syncOn) await sync.signOut();
  // 初めての同期の前に取ったバックアップ（本棚の完全な写し）も残さない
  await sync.deleteLocalBackups();
  if (!context.mounted) return;
  // 設定画面などを閉じて最初の画面に戻してから消す（言語選択画面からやり直すため）
  Navigator.of(context).popUntil((route) => route.isFirst);
  repo.wipeAllData();
  library.reload();
  await settings.resetAll();
  messenger.showSnackBar(SnackBar(content: Text(l.deleteAllDone)));
}