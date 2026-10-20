import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/book_repository.dart';
import 'l10n/app_localizations.dart';
import 'services/google_auth.dart';
import 'services/isbn_lookup.dart';
import 'state/library_controller.dart';
import 'state/settings_controller.dart';
import 'state/sync_controller.dart';
import 'ui/app_theme.dart';
import 'ui/barcode_scanner.dart';
import 'ui/book_list_screen.dart';
import 'ui/common.dart';
import 'ui/language_select_screen.dart';

/// 終了時の「同期しています」の画面を、どの画面の上にも出すため。
final _navigatorKey = GlobalKey<NavigatorState>();

class ColophonApp extends StatelessWidget {
  const ColophonApp({
    super.key,
    required this.settings,
    required this.repository,
    this.lookupService,
    this.sync,
    this.isbnScanner = scanIsbnWithCamera,
  });

  final SettingsController settings;
  final BookRepository repository;

  /// テストで差し替えるためのもの。通常は null（実サービスを使う）。
  final IsbnLookupService? lookupService;

  /// 省略すると同期を使えない状態になる（テスト用）。
  final SyncController? sync;

  /// バーコードの読み取り。テストでカメラの代わりに使う関数を渡す。
  final IsbnScanner isbnScanner;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: repository),
        ChangeNotifierProvider(create: (_) {
          final library = LibraryController(repository, settings.sort);
          // 同期でこの端末のデータが変わったら、一覧を読み直す
          sync?.onLocalDataChanged = library.reload;
          return library;
        }),
        Provider<IsbnScanner>.value(value: isbnScanner),
        Provider<IsbnLookupService>(
          create: (_) => lookupService ?? IsbnLookupService(),
          dispose: (_, service) => service.close(),
        ),
        if (sync != null)
          ChangeNotifierProvider.value(value: sync!)
        else
          ChangeNotifierProvider(create: (_) => SyncController(const UnconfiguredGoogleAuth())),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          builder: (context, child) => _SyncBeforeExit(navigatorKey: _navigatorKey, child: child!),
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

/// アプリを終了する前に、まだ送っていない変更を同期する。
///
/// 編集画面の「保存していない変更を破棄しますか」の確認は、この後に呼ばれる（登録順）。
/// 確認で終了を取りやめた場合も、同期しておいて困ることはない。
class _SyncBeforeExit extends StatefulWidget {
  const _SyncBeforeExit({required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<_SyncBeforeExit> createState() => _SyncBeforeExitState();
}

class _SyncBeforeExitState extends State<_SyncBeforeExit> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onExitRequested: _syncThenExit,
      // スマホ・タブレットには終了の操作がないので、裏に回ったときと戻ったときに同期する
      // （パソコンでは、最小化のたびに同期しないよう呼ばない）
      onHide: () {
        if (isMobilePlatform) context.read<SyncController>().onBackgrounded();
      },
      onShow: () {
        if (isMobilePlatform) context.read<SyncController>().onResumed();
      },
    );
  }

  /// 送っていない変更があれば、「同期しています」の画面を出して同期してから終了する。
  /// 画面を出している間は操作できない（同期中の編集が送られずに残るのを防ぐ）。
  /// 「同期せずに終了」を押せば待たずに終了する（変更はこの端末に残り、次に起動したときに送る）。
  Future<AppExitResponse> _syncThenExit() async {
    final sync = context.read<SyncController>();
    final navigatorContext = widget.navigatorKey.currentContext;
    if (!sync.hasUnsentChanges || navigatorContext == null) {
      await sync.syncBeforeExit();
      return AppExitResponse.exit;
    }
    final skip = Completer<void>();
    final navigator = Navigator.of(navigatorContext);
    var open = true;
    unawaited(showDialog<void>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (_) => PopScope(canPop: false, child: _ExitSyncDialog(onSkip: skip.complete)),
    ).whenComplete(() => open = false));
    await Future.any([sync.syncBeforeExit(), skip.future]);
    if (open) navigator.pop();
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ExitSyncDialog extends StatelessWidget {
  const _ExitSyncDialog({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Row(children: [
        const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(width: 16),
        Expanded(child: Text(l.syncOnExitTitle)),
      ]),
      content: Text(l.syncOnExitBody),
      actions: [TextButton(onPressed: onSkip, child: Text(l.syncOnExitSkip))],
    );
  }
}
