import 'package:colophon/app.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/services/isbn_lookup.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// バーコードからの登録。カメラは使えないため、読み取りは偽の関数で差し替える。
/// テストの実行環境は既定で Android 扱いのため、パソコンの動きは TargetPlatformVariant で確かめる。
void main() {
  late BookRepository repo;
  late _FakeLookup lookup;
  late List<String?> scans;
  late int scanCount;

  setUp(() {
    repo = newRepository();
    lookup = _FakeLookup();
    scans = [];
    scanCount = 0;
  });
  tearDown(() => repo.db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'language': 'ja'});
    final settings = SettingsController(await SharedPreferences.getInstance());
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ColophonApp(
      settings: settings,
      repository: repo,
      lookupService: lookup,
      isbnScanner: (_) async {
        scanCount++;
        return scans.isEmpty ? null : scans.removeAt(0);
      },
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('一覧のバーコードボタンで読み取ると、登録画面に ISBN を入れ、書籍情報を取得して反映できる', (tester) async {
    scans = ['9784309226712'];
    await pumpApp(tester);

    await tester.tap(find.byTooltip('バーコードで追加'));
    await tester.pumpAndSettle();

    expect(find.text('書籍の登録'), findsOneWidget);
    expect(lookup.asked, ['9784309226712'], reason: '読み取った ISBN で自動的に取得する');
    await tester.tap(find.text('選んだ項目を反映'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final book = repo.getAllBooks().single;
    expect(book.isbn, '9784309226712');
    expect(book.title, 'サピエンス全史 上');
  });

  testWidgets('読み取りをやめたときは、登録画面を開かない', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('バーコードで追加'));
    await tester.pumpAndSettle();

    expect(scanCount, 1);
    expect(find.text('書籍の登録'), findsNothing);
    expect(lookup.asked, isEmpty);
  });

  testWidgets('読み取って開いただけなら、保存せずに戻っても確認を出さない', (tester) async {
    scans = ['9784309226712'];
    await pumpApp(tester);
    await tester.tap(find.byTooltip('バーコードで追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル')); // 取得結果を反映しない
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('書籍の登録'), findsNothing);
    expect(repo.countBooks(), 0);
  });

  testWidgets('読み取った本の情報が見つからないときは、ISBN を残して書籍名の入力から始められる', (tester) async {
    scans = ['9784309226712'];
    lookup.found = false;
    await pumpApp(tester);
    await tester.tap(find.byTooltip('バーコードで追加'));
    await tester.pumpAndSettle();

    expect(find.text('このISBNの書籍は見つかりませんでした。'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '9784309226712'), findsOneWidget);
    final title = tester.widget<EditableText>(
        find.descendant(of: find.widgetWithText(TextFormField, '書籍名 *'), matching: find.byType(EditableText)));
    expect(title.focusNode.hasFocus, isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('書籍の登録'), findsNothing, reason: '読み取っただけなので確認を出さずに戻る');
  });

  testWidgets('編集画面の ISBN 欄の横のボタンで読み取ると、ISBN を入れて書籍情報を取得する', (tester) async {
    scans = ['9784309226712'];
    await pumpApp(tester);
    await tester.tap(find.text('書籍を追加'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('バーコードを読み取る'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '9784309226712'), findsOneWidget);
    expect(lookup.asked, ['9784309226712']);

    await tester.tap(find.text('キャンセル')); // 取得結果は反映しない
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('破棄'), findsOneWidget, reason: '編集画面で読み取った ISBN は入力した変更として扱う');
  });

  testWidgets('パソコンでは、バーコードのボタンを出さない', variant: TargetPlatformVariant.only(TargetPlatform.windows),
      (tester) async {
    await pumpApp(tester);
    expect(find.byTooltip('バーコードで追加'), findsNothing);

    await tester.tap(find.text('書籍を追加'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('バーコードを読み取る'), findsNothing);
  });
}

class _FakeLookup extends IsbnLookupService {
  final asked = <String>[];
  bool found = true;

  @override
  Future<LookupResult?> lookup(String isbn) async {
    asked.add(isbn);
    if (!found) return null;
    return const LookupResult(source: LookupSource.ndl, title: 'サピエンス全史 上', author: 'ユヴァル・ノア・ハラリ');
  }
}
