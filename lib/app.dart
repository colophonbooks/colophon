import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/book_repository.dart';
import 'l10n/app_localizations.dart';
import 'services/isbn_lookup.dart';
import 'state/library_controller.dart';
import 'state/settings_controller.dart';
import 'ui/app_theme.dart';
import 'ui/book_list_screen.dart';
import 'ui/language_select_screen.dart';

class ColophonApp extends StatelessWidget {
  const ColophonApp({
    super.key,
    required this.settings,
    required this.repository,
    this.lookupService,
  });

  final SettingsController settings;
  final BookRepository repository;

  /// テストで差し替えるためのもの。通常は null（実サービスを使う）。
  final IsbnLookupService? lookupService;


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: repository),
        ChangeNotifierProvider(create: (_) => LibraryController(repository, settings.sort)),
        Provider<IsbnLookupService>(
          create: (_) => lookupService ?? IsbnLookupService(),
          dispose: (_, service) => service.close(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Colophon',
          debugShowCheckedModeBanner: false,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(settings.colorTheme, Brightness.light),
          darkTheme: buildTheme(settings.colorTheme, Brightness.dark),
          themeMode: settings.themeMode,
          home: settings.hasChosenLanguage ? const BookListScreen() : const LanguageSelectScreen(),
        ),
      ),
    );
  }
}
