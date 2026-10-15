import 'dart:typed_data';

import 'package:colophon/services/cover_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Uint8List _png(int w, int h) => img.encodePng(img.Image(width: w, height: h));

/// 圧縮が効きにくい（ファイルサイズが大きくなる）画像。
Uint8List _noisyPng(int w, int h) {
  final image = img.Image(width: w, height: h);
  var seed = 1;
  for (final p in image) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    p
      ..r = seed & 0xff
      ..g = (seed >> 8) & 0xff
      ..b = (seed >> 16) & 0xff;
  }
  return img.encodePng(image);
}

void main() {
  test('基準以下の画像はそのまま保存する', () {
    final bytes = _png(800, 1200);
    final r = processCoverSync(bytes, autoResize: true);
    expect(r.resized, isFalse);
    expect(r.bytes, same(bytes));
    expect(r.mimeType, 'image/png');
  });

  test('長辺が2000pxを超える画像は長辺2000pxに縮小する（縦横比は保つ）', () {
    final r = processCoverSync(_png(1500, 3000), autoResize: true);
    expect(r.resized, isTrue);
    expect((r.width, r.height), (1000, 2000));
    expect(r.mimeType, 'image/jpeg');
  });

  test('2000px以下でも2MBを超える画像は再圧縮して小さくする', () {
    final bytes = _noisyPng(1000, 1000);
    expect(bytes.length, greaterThan(coverMaxBytes));
    final r = processCoverSync(bytes, autoResize: true);
    expect(r.resized, isTrue);
    expect((r.width, r.height), (1000, 1000));
    expect(r.bytes.length, lessThan(bytes.length));
  });

  test('自動縮小が無効なら大きな画像もそのまま保存する', () {
    final bytes = _png(1500, 3000);
    final r = processCoverSync(bytes, autoResize: false);
    expect(r.resized, isFalse);
    expect(r.bytes, same(bytes));
  });

  test('サムネイルは長辺360px以下で作る', () {
    final r = processCoverSync(_png(1000, 1500), autoResize: true);
    final thumb = img.decodeImage(r.thumbnail)!;
    expect((thumb.width, thumb.height), (240, 360));
  });

  test('一般的でない形式（TIFF）は表示できる形式に変換して保存する', () {
    final r = processCoverSync(img.encodeTiff(img.Image(width: 100, height: 150)), autoResize: false);
    expect(r.mimeType, 'image/jpeg');
    expect(mimeTypeOf(r.bytes), 'image/jpeg');
  });

  test('画像でないデータは例外にする', () {
    expect(
      () => processCoverSync(Uint8List.fromList([1, 2, 3]), autoResize: true),
      throwsA(isA<CoverImageException>()),
    );
  });
}
