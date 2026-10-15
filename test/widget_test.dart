import 'package:colophon/app.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/models/book.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:colophon/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  late BookRepository repo;

  setUp(() => repo = newRepository());
  tearDown(() => repo.db.close());

  Future<SettingsController> pumpApp(WidgetTester tester, {String? language}) async {
    SharedPreferences.setMockInitialValues({'language': ?language});
    final settings = SettingsController(await SharedPreferences.getInstance());
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ColophonApp(settings: settings, repository: repo));
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('初回起動時は言語を選び、選んだ言語で一覧画面を表示する', (tester) async {
    final settings = await pumpApp(tester);
    expect(find.text('Choose your language'), findsOneWidget);

    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();
    expect(find.text('表示言語を選んでください'), findsOneWidget, reason: '選んだ言語がその場で反映される');

    await tester.tap(find.text('続ける'));
    await tester.pumpAndSettle();
    expect(settings.hasChosenLanguage, isTrue);
    expect(find.textContaining('まだ書籍がありません'), findsOneWidget);
  });

  testWidgets('書籍名だけで登録でき、一覧に表示される', (tester) async {
    await pumpApp(tester, language: 'ja');
    await tester.tap(find.text('書籍を追加'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('書籍名を入力してください。'), findsOneWidget, reason: '書籍名は必須');

    await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '吾輩は猫である');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('吾輩は猫である'), findsOneWidget);
    expect(find.text('未設定'), findsOneWidget, reason: '初期ステータスは未設定');
    expect(repo.countBooks(), 1);
  });

  testWidgets('Enter を押していないタグや、非表示になった範囲外の進捗があっても保存できる', (tester) async {
    await pumpApp(tester, language: 'ja');
    await tester.tap(find.text('書籍を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), 'テスト本');

    // 読書中にして範囲外の進捗を入れてから、ステータスを読了に変える
    await tester.tap(find.text('未設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('読書中').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '読んだ割合（%）'), '150');
    await tester.tap(find.text('読書中'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('読了').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'), warnIfMissed: false); // 読了日の記録は今回は追加しない
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'タグを入力して Enter'), '入力途中');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final book = repo.getAllBooks().single;
    expect(book.status, ReadingStatus.finished);
    expect(book.progress, isNull);
    expect(book.tags, ['入力途中']);
  });

  testWidgets('読書中の進捗%は入力されているときだけ一覧に表示する', (tester) async {
    repo.saveBook(sampleBook(title: '進捗あり', status: ReadingStatus.reading, progress: 40));
    repo.saveBook(sampleBook(title: '進捗なし', status: ReadingStatus.reading));
    repo.saveBook(sampleBook(title: '読了本', status: ReadingStatus.finished, progress: 80));
    await pumpApp(tester, language: 'ja');

    expect(find.text('読書中 40%'), findsOneWidget);
    expect(find.text('読書中'), findsOneWidget);
    expect(find.text('読了'), findsOneWidget, reason: '読書中以外では保持している%を表示しない');
  });

  testWidgets('書籍名の一覧と書影の一覧を切り替えられる', (tester) async {
    repo.saveBook(sampleBook(title: '切り替えテスト'));
    final settings = await pumpApp(tester, language: 'ja');
    expect(find.byType(ListTile), findsOneWidget);

    await tester.tap(find.byTooltip('書影で表示'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(settings.gridView, isTrue);

    await tester.tap(find.byTooltip('書籍名で表示'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('設定画面で配色テーマと明るさを選ぶと、画面全体に反映され保存される', (tester) async {
    final settings = await pumpApp(tester, language: 'ja');
    final before = Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.primary;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester.tap(find.text('モノクロ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('暗い'));
    await tester.pumpAndSettle();

    expect(settings.colorTheme, ColorThemeId.monochrome);
    expect(settings.themeMode, ThemeMode.dark);
    final theme = Theme.of(tester.element(find.byType(SettingsScreen)));
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, isNot(before));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('colorTheme'), 'monochrome');
    expect(prefs.getString('themeMode'), 'dark');
  });

  testWidgets('エクスポートの形式選択で「書影も含める」を選ぶと、次回も選ばれた状態になる', (tester) async {
    repo.saveBook(sampleBook(title: '書き出す本'));
    final settings = await pumpApp(tester, language: 'ja');

    Future<void> openExportDialog() async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('エクスポート'));
      await tester.pumpAndSettle();
    }

    await openExportDialog();
    final checkbox = find.widgetWithText(CheckboxListTile, '書影も含める（ZIPで保存）');
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
    expect(settings.exportTextWithCovers, isTrue);

    await tester.tapAt(const Offset(5, 5)); // ダイアログの外を押して閉じる
    await tester.pumpAndSettle();
    await openExportDialog();
    expect(tester.widget<CheckboxListTile>(checkbox).value, isTrue);
  });

  testWidgets('編集画面でノートの☆を押して保存すると、お気に入りになる', (tester) async {
    repo.saveBook(sampleBook(title: 'お気に入りテスト', notes: [Note(uuid: 'n-1', body: '残したい一文')]));
    await pumpApp(tester, language: 'ja');
    await tester.tap(find.text('お気に入りテスト'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('お気に入りに追加'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('お気に入りから外す'), findsOneWidget);
    expect(repo.getAllBooks().single.notes.single.favorite, isFalse, reason: '保存するまでは確定しない');

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.getAllBooks().single.notes.single.favorite, isTrue);
  });

  testWidgets('検索結果のノートの☆は、押した時点で保存される', (tester) async {
    repo.saveBook(sampleBook(title: '検索で印を付ける本', notes: [Note(uuid: 'n-1', body: '心に残った言葉')]));
    await pumpApp(tester, language: 'ja');
    await tester.tap(find.byTooltip('検索'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '心に残った');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('お気に入りに追加'));
    await tester.pumpAndSettle();

    expect(repo.getAllBooks().single.notes.single.favorite, isTrue);
    expect(find.byTooltip('お気に入りから外す'), findsOneWidget);
  });

  group('ビューアモード', () {
    Future<void> openBook(WidgetTester tester, String title) async {
      await pumpApp(tester, language: 'ja');
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }

    testWidgets('登録済みの書籍はビューアモードで開き、未入力の項目・編集用の操作を出さない', (tester) async {
      repo.saveBook(sampleBook(
        title: '見るだけの本',
        author: '著者A',
        translator: null,
        tags: ['哲学'],
        notes: [
          Note(category: NoteCategory.excerpt, page: 30, body: '抜粋の本文', favorite: true),
          Note(body: '分類もページもないメモ'),
        ],
      ));
      await openBook(tester, '見るだけの本');

      expect(find.text('書籍の詳細'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing, reason: '入力欄を出さない');
      expect(find.text('保存'), findsNothing);
      expect(find.byTooltip('書籍を削除'), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsNothing, reason: '並べ替えのアイコンを出さない');
      expect(find.byTooltip('ノートを削除'), findsNothing);
      expect(find.byTooltip('お気に入りに追加'), findsNothing, reason: '☆ボタン（切り替え）を出さない');

      expect(find.textContaining('著者A', findRichText: true), findsOneWidget);
      expect(find.textContaining('翻訳者', findRichText: true), findsNothing, reason: '未入力の項目は見出しごと出さない');
      expect(find.text('読了日'), findsNothing, reason: '読了日がなければ見出しも出さない');
      expect(find.text('哲学'), findsOneWidget);
      expect(find.text('抜粋 · p.30'), findsOneWidget);
      expect(find.text('抜粋の本文'), findsOneWidget);
      expect(find.text('分類もページもないメモ'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget, reason: 'お気に入りのノートだけ★');
    });

    testWidgets('ビューアの★は押しても切り替わらない', (tester) async {
      repo.saveBook(sampleBook(title: '★の本', notes: [Note(body: '本文', favorite: true)]));
      await openBook(tester, '★の本');
      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();
      expect(repo.getAllBooks().single.notes.single.favorite, isTrue);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('編集に切り替えて変更がなければ、そのままビューアに戻れる', (tester) async {
      repo.saveBook(sampleBook(title: '切り替える本'));
      await openBook(tester, '切り替える本');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      expect(find.text('書籍の編集'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);

      await tester.tap(find.text('表示'));
      await tester.pumpAndSettle();
      expect(find.text('書籍の詳細'), findsOneWidget);
      expect(find.text('変更を破棄しますか？'), findsNothing);
    });

    testWidgets('未保存の変更があれば確認し、「保存して表示」で保存した内容を表示する', (tester) async {
      repo.saveBook(sampleBook(title: '直す前の書名'));
      await openBook(tester, '直す前の書名');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '直した書名');
      await tester.tap(find.text('表示'));
      await tester.pumpAndSettle();

      expect(find.text('変更を破棄しますか？'), findsOneWidget);
      await tester.tap(find.text('保存して表示'));
      await tester.pumpAndSettle();

      expect(find.text('書籍の詳細'), findsOneWidget);
      expect(find.text('直した書名'), findsOneWidget);
      expect(repo.getAllBooks().single.title, '直した書名');
    });

    testWidgets('「破棄して表示」では変更を捨て、保存済みの内容を表示する', (tester) async {
      repo.saveBook(sampleBook(title: '元の書名'));
      await openBook(tester, '元の書名');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '捨てる書名');
      await tester.tap(find.text('表示'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('破棄して表示'));
      await tester.pumpAndSettle();

      expect(find.text('元の書名'), findsOneWidget);
      expect(repo.getAllBooks().single.title, '元の書名');

      // もう一度編集に入ると、捨てた変更は残っていない
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '元の書名'), findsOneWidget);
    });

    testWidgets('「キャンセル」なら編集モードのまま変更も残る', (tester) async {
      repo.saveBook(sampleBook(title: '元の書名'));
      await openBook(tester, '元の書名');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '編集中の書名');
      await tester.tap(find.text('表示'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(find.text('書籍の編集'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '編集中の書名'), findsOneWidget);
    });

    testWidgets('日付は年を含めて表示する', (tester) async {
      repo.saveBook(sampleBook(title: '日付の本', readDates: [const LocalDate(2025, 3, 1)]));
      await openBook(tester, '日付の本');
      expect(find.text('2025年3月1日'), findsOneWidget);
    });

    testWidgets('登録済みの書籍は「保存」でビューアに戻り、保存した内容を表示する', (tester) async {
      repo.saveBook(sampleBook(title: '保存前の書名'));
      await openBook(tester, '保存前の書名');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '保存後の書名');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('書籍の詳細'), findsOneWidget, reason: '一覧ではなくビューアに戻る');
      expect(find.text('保存後の書名'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(repo.getAllBooks().single.title, '保存後の書名');

      // 戻ると一覧にも反映されている
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('保存後の書名'), findsOneWidget);
    });

    testWidgets('入力エラーで保存できないときは編集モードのまま', (tester) async {
      repo.saveBook(sampleBook(title: '消してみる書名'));
      await openBook(tester, '消してみる書名');
      await tester.tap(find.text('編集'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('書籍の編集'), findsOneWidget);
      expect(find.text('書籍名を入力してください。'), findsOneWidget);
    });

    testWidgets('新規登録では切り替えを出さず、編集モードで開く', (tester) async {
      await pumpApp(tester, language: 'ja');
      await tester.tap(find.text('書籍を追加'));
      await tester.pumpAndSettle();
      expect(find.text('書籍の登録'), findsOneWidget);
      expect(find.byType(SegmentedButton<bool>), findsNothing);
    });
  });

  group('すべてのデータを削除', () {
    Future<void> openDeleteDialog(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('すべてのデータを削除'), 200);
      await tester.tap(find.text('すべてのデータを削除'));
      await tester.pumpAndSettle();
    }

    testWidgets('二段階で確認し、削除後は言語選択画面から始まる', (tester) async {
      repo.saveBook(sampleBook(title: '消える本'));
      final settings = await pumpApp(tester, language: 'ja');
      await openDeleteDialog(tester);

      expect(find.textContaining('登録した1冊'), findsOneWidget);
      await tester.tap(find.text('削除へ進む'));
      await tester.pumpAndSettle();

      final deleteButton = find.widgetWithText(FilledButton, 'すべて削除');
      expect(tester.widget<FilledButton>(deleteButton).onPressed, isNull, reason: 'チェックするまで押せない');
      await tester.tap(find.text('削除したデータは元に戻せないことを理解しました'));
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(repo.countBooks(), 0);
      expect(settings.hasChosenLanguage, isFalse);
      expect(find.text('Choose your language'), findsOneWidget, reason: '言語選択画面からやり直す');
    });

    testWidgets('キャンセルすれば何も消えない', (tester) async {
      repo.saveBook(sampleBook(title: '残る本'));
      final settings = await pumpApp(tester, language: 'ja');
      await openDeleteDialog(tester);
      await tester.tap(find.text('削除へ進む'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      expect(repo.countBooks(), 1);
      expect(settings.hasChosenLanguage, isTrue);
    });
  });

  testWidgets('保存せずに戻ろうとすると破棄の確認を出す', (tester) async {
    await pumpApp(tester, language: 'ja');
    await tester.tap(find.text('書籍を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '途中まで');
    // 端末の「戻る」操作（Android の戻るボタン、Esc キー等）と同じ経路で戻る
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('変更を破棄しますか？'), findsOneWidget);
    await tester.tap(find.text('破棄'));
    await tester.pumpAndSettle();
    expect(find.textContaining('まだ書籍がありません'), findsOneWidget);
    expect(repo.countBooks(), 0);
  });
}
