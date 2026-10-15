import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/settings_controller.dart';
import 'common.dart';

/// 初回起動時の言語選択。選んだ言語がその場で画面に反映される。
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final device = WidgetsBinding.instance.platformDispatcher.locale;
    _selected = SettingsController.initialLanguageFor(device);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SettingsController>().previewLanguage(_selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 480,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Icon(Icons.auto_stories_outlined, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Colophon', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 32),
              Text(l.chooseLanguageTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l.chooseLanguageNote, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final lang in supportedLanguages)
                      ListTile(
                        title: Text(lang.name),
                        selected: lang.code == _selected,
                        trailing: lang.code == _selected ? const Icon(Icons.check) : null,
                        onTap: () {
                          setState(() => _selected = lang.code);
                          context.read<SettingsController>().previewLanguage(lang.code);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.read<SettingsController>().setLanguage(_selected),
                child: Text(l.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
