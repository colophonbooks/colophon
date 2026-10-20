import 'package:colophon/app.dart';
import 'package:colophon/data/book_repository.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// スマホ・タブレットでの写真の取り込みとファイルの選択。
/// テストの実行環境は既定で Android 扱いのため、パソコンの動きは debugDefaultTargetPlatformOverride で確かめる。
void main() {
  late BookRepository repo;
  late _FakeImagePicker imagePicker;
  late _FakeFilePicker filePicker;

  setUp(() {
    repo = newRepository();
    imagePicker = _FakeImagePicker();
    filePicker = _FakeFilePicker();
    ImagePickerPlatform.instance = imagePicker;
    FilePickerPlatform.instance = filePicker;
  });
  tearDown(() => repo.db.close());

  /// [keepPrefs] が true なら、テストの中で先に保存した設定をそのまま使う。
  Future<void> pumpApp(WidgetTester tester, {bool keepPrefs = false}) async {
    if (!keepPrefs) SharedPreferences.setMockInitialValues({'language': 'ja'});
    final settings = SettingsController(await SharedPreferences.getInstance());
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ColophonApp(settings: settings, repository: repo));
    await tester.pumpAndSettle();
  }

  Future<void> openNewBook(WidgetTester tester) async {
    await tester.tap(find.text('書籍を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '書籍名 *'), '撮影した本');
  }

  /// 書影の処理は別 Isolate で行うため、実時間を進めて終わるのを待つ。
  Future<void> chooseAndWait(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();
  }

  testWidgets('スマホでは、書影をカメラで撮って登録できる', (tester) async {
    imagePicker.result = XFile.fromData(_png(30, 45), mimeType: 'image/png');
    await pumpApp(tester);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    expect(find.text('写真から選ぶ'), findsOneWidget);
    await chooseAndWait(tester, 'カメラで撮る');
    expect(imagePicker.sources, [ImageSource.camera]);
    expect(imagePicker.options.single.maxWidth, 2000, reason: '自動縮小が有効なら端末側で縮めてから受け取る');
    expect(imagePicker.options.single.requestFullMetadata, isFalse, reason: 'iOS で写真全体へのアクセス許可を求めない');

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.getAllBooks().single.cover, isNotNull);
  });

  testWidgets('スマホでは、書影を写真の一覧から選べる', (tester) async {
    imagePicker.result = XFile.fromData(_png(30, 45), mimeType: 'image/png');
    await pumpApp(tester);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    await chooseAndWait(tester, '写真から選ぶ');

    expect(imagePicker.sources, [ImageSource.gallery]);
    expect(find.text('画像を削除'), findsOneWidget, reason: '書影が入った');
  });

  testWidgets('カメラを使えないときは、その旨を伝え、書影は変えない', (tester) async {
    imagePicker.error = PlatformException(code: 'no_available_camera');
    await pumpApp(tester);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    await chooseAndWait(tester, 'カメラで撮る');

    expect(find.text('カメラを使えませんでした。カメラの使用を許可しているか確認してください。'), findsOneWidget);
    expect(find.text('画像を削除'), findsNothing);
  });

  testWidgets('写真の一覧から取り出せなかったときは、カメラの案内ではなく読み込めなかったことを伝える', (tester) async {
    imagePicker.error = PlatformException(code: 'invalid_image');
    await pumpApp(tester);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    await chooseAndWait(tester, '写真から選ぶ');

    expect(find.text('この画像は読み込めませんでした。'), findsOneWidget);
    expect(find.textContaining('カメラを使えません'), findsNothing);
  });

  testWidgets('選択肢を閉じたときや、撮影・選択をやめたときは、何も変えず何も出さない', (tester) async {
    await pumpApp(tester);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(500, 100)); // 選択肢の外を押して閉じる
    await tester.pumpAndSettle();
    expect(imagePicker.sources, isEmpty);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    await chooseAndWait(tester, 'カメラで撮る'); // 偽のカメラは何も返さない（やめた）
    expect(imagePicker.sources, [ImageSource.camera]);
    expect(find.text('画像を削除'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('自動縮小を切っているときは、端末側でも縮めずに受け取る', (tester) async {
    SharedPreferences.setMockInitialValues({'language': 'ja'});
    await SettingsController(await SharedPreferences.getInstance()).setAutoResize(false);
    imagePicker.result = XFile.fromData(_png(30, 45), mimeType: 'image/png');
    await pumpApp(tester, keepPrefs: true);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();
    await chooseAndWait(tester, 'カメラで撮る');

    expect(imagePicker.options.single.maxWidth, isNull);
  });

  testWidgets('パソコンでは、書影はカメラを選ばせず、ファイルから選ぶ', variant: TargetPlatformVariant.only(TargetPlatform.windows),
      (tester) async {
    await pumpApp(tester);
    await openNewBook(tester);

    await tester.tap(find.text('画像を選択'));
    await tester.pumpAndSettle();

    expect(find.text('カメラで撮る'), findsNothing);
    expect(filePicker.types, [FileType.image]);
  });

  group('インポートのファイル選択', () {
    Future<void> openImport(WidgetTester tester) async {
      await pumpApp(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('インポート'));
      await tester.pumpAndSettle();
    }

    testWidgets('スマホでは種類で絞り込まない（SQLite のファイルが選べなくなるため）', (tester) async {
      await openImport(tester);

      expect(filePicker.types, [FileType.any]);
      expect(filePicker.allowedExtensions, [null]);
    });

    testWidgets('パソコンでは、読み込める拡張子に絞り込む', variant: TargetPlatformVariant.only(TargetPlatform.windows),
        (tester) async {
      await openImport(tester);

      expect(filePicker.types, [FileType.custom]);
      expect(filePicker.allowedExtensions.single, containsAll(['zip', 'sqlite']));
    });
  });
}

Uint8List _png(int w, int h) => img.encodePng(img.Image(width: w, height: h));

class _FakeImagePicker extends ImagePickerPlatform {
  XFile? result;
  PlatformException? error;
  final sources = <ImageSource>[];
  final options = <ImageOptions>[];

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    sources.add(source);
    this.options.add(options);
    if (error != null) throw error!;
    return result;
  }
}

class _FakeFilePicker extends FilePickerPlatform {
  final types = <FileType>[];
  final allowedExtensions = <List<String>?>[];

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    types.add(type);
    this.allowedExtensions.add(allowedExtensions);
    return null;
  }
}
