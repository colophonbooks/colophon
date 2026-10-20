import 'package:colophon/app.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/l10n/app_localizations.dart';
import 'package:colophon/models/book.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// スマホの幅での配置。はみ出し（RenderFlex overflowed）はテストの失敗として報告される。
void main() {
  late BookRepository repo;

  setUp(() {
    repo = newRepository();
    repo.saveBook(sampleBook(
      title: '草枕',
      status: ReadingStatus.reading,
      progress: 40,
      notes: [
        Note(category: NoteCategory.impression, page: 12, favorite: true, body: '山路を登りながら、こう考えた。'),
        Note(body: 'メモ'),
      ],
      readDates: [const LocalDate(2026, 9, 20)],
      tags: ['小説'],
    ));
  });
  tearDown(() => repo.db.close());

  /// 幅 [width]（既定は、よくある小さめのスマホの 360）の画面で起動する。
  /// 高さは、画面の最後まで一度に作られるよう大きく取る。
  Future<void> pumpPhone(WidgetTester tester, String language,
      {double width = 360, double height = 3000, FakeViewPadding padding = FakeViewPadding.zero}) async {
    SharedPreferences.setMockInitialValues({'language': language});
    final settings = SettingsController(await SharedPreferences.getInstance());
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = padding;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ColophonApp(settings: settings, repository: repo));
    await tester.pumpAndSettle();
  }

  Future<void> openBook(WidgetTester tester) async {
    await tester.tap(find.text('草枕'));
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    await openBook(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
  }

  void expectCompactToolbar(WidgetTester tester, AppLocalizations l) {
    expect(find.byTooltip(l.save), findsOneWidget, reason: '保存はアイコンのボタン（名前はツールチップ）');
    expect(find.text(l.save), findsNothing);
  }

  for (final locale in AppLocalizations.supportedLocales) {
    final l = lookupAppLocalizations(locale);

    testWidgets('スマホの幅では、編集画面の上部はアイコンだけになり、ノートの欄もはみ出さない（${locale.languageCode}）',
        (tester) async {
      await pumpPhone(tester, locale.languageCode);
      await openEditor(tester);

      expectCompactToolbar(tester, l);
      expect(find.byTooltip(l.viewMode), findsOneWidget);
      expect(find.text(l.editMode), findsNothing);
      final check = tester.element(find.byIcon(Icons.check));
      expect(IconTheme.of(check).color, Theme.of(check).colorScheme.onPrimary, reason: '塗りつぶしの上で読める色');
      expect(find.text(l.editBookTitle), findsNothing, reason: '切れて読めない題名は出さない');
      expect(find.byIcon(Icons.arrow_downward), findsNWidgets(2), reason: 'ノート2件分のボタンが出ている');
    });

    testWidgets('スマホの幅では、設定画面の明るさの切り替えを文字だけにする（${locale.languageCode}）', (tester) async {
      await pumpPhone(tester, locale.languageCode);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.menuSettings));
      await tester.pumpAndSettle();

      expect(find.text(l.brightnessSystem), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
    });
  }

  testWidgets('スマホの幅の表示モードでは、題名を出し、表示/編集の切り替えはアイコンだけにする', (tester) async {
    await pumpPhone(tester, 'ja');
    await openBook(tester);

    expect(find.text('書籍の詳細'), findsOneWidget);
    expect(find.byTooltip('編集'), findsOneWidget);
    expect(find.text('編集'), findsNothing);
  });

  testWidgets('スマホの幅の新規登録では、題名とアイコンの保存ボタンを出す', (tester) async {
    await pumpPhone(tester, 'ja');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('書籍の登録'), findsOneWidget);
    expectCompactToolbar(tester, lookupAppLocalizations(const Locale('ja')));
  });

  testWidgets('スマホの幅の編集画面でも、アイコンの保存ボタンで保存できる', (tester) async {
    await pumpPhone(tester, 'ja');
    await openEditor(tester);
    await tester.enterText(find.widgetWithText(TextFormField, '草枕'), '草枕（改版）');
    await tester.tap(find.byTooltip('保存'));
    await tester.pumpAndSettle();

    expect(repo.getAllBooks().single.title, '草枕（改版）');
  });

  for (final language in ['de', 'fr']) {
    testWidgets('横向きのスマホ（幅 640・左右に切り欠き）でも、編集画面の上部がはみ出さない（$language）', (tester) async {
      await pumpPhone(tester, language,
          width: 640, padding: const FakeViewPadding(left: 48, right: 48));
      await openEditor(tester);

      expectCompactToolbar(tester, lookupAppLocalizations(Locale(language)));
    });
  }

  for (final newBook in [true, false]) {
    testWidgets('文字サイズを大きくしたスマホでも、${newBook ? '新規登録' : '編集'}の画面がはみ出さない', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpPhone(tester, 'de');
      if (newBook) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
      } else {
        await openEditor(tester);
      }

      expect(find.byTooltip('Speichern'), findsOneWidget);
    });
  }

  testWidgets('画面の下端に OS のバー（ジェスチャーバーなど）があるときは、その分を空けて本文を表示する', (tester) async {
    await pumpPhone(tester, 'ja', height: 800, padding: const FakeViewPadding(bottom: 48));
    await openEditor(tester);

    expect(tester.getBottomLeft(find.byType(ListView).first).dy, 800 - 48);
  });

  testWidgets('ダイアログの背景の暗転は、OS のバーの部分も含めて画面全体に掛かる', (tester) async {
    await pumpPhone(tester, 'ja', height: 800, padding: const FakeViewPadding(bottom: 48));
    await openEditor(tester);
    await tester.tap(find.byTooltip('書籍を削除'));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(ModalBarrier).last), const Rect.fromLTWH(0, 0, 360, 800));
  });
}
