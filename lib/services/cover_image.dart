import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 縮小対象とする長辺のピクセル数と、縮小後の長辺。
const int coverMaxSide = 2000;

/// 縮小対象とするファイルサイズ（2MB）。
const int coverMaxBytes = 2 * 1024 * 1024;

/// 一覧表示用サムネイルの長辺。
const int thumbnailSide = 360;

class ProcessedCover {
  const ProcessedCover({
    required this.bytes,
    required this.mimeType,
    required this.thumbnail,
    required this.width,
    required this.height,
    required this.resized,
  });

  final Uint8List bytes;
  final String mimeType;
  final Uint8List thumbnail;
  final int width;
  final int height;

  /// 自動縮小（または再圧縮）を行ったか。
  final bool resized;
}

class CoverImageException implements Exception {}

/// 画像を検証し、必要なら縮小してサムネイルを作る。重い処理なので別 Isolate で実行する。
Future<ProcessedCover> processCover(Uint8List bytes, {required bool autoResize}) =>
    Isolate.run(() => processCoverSync(bytes, autoResize: autoResize));

/// サムネイルだけを作り直す（インポート時に使用）。読めない画像は null。
Future<Uint8List?> makeThumbnail(Uint8List bytes) => Isolate.run(() {
      final image = _decode(bytes);
      return image == null ? null : _thumbnailOf(image);
    });

ProcessedCover processCoverSync(Uint8List bytes, {required bool autoResize}) {
  final image = _decode(bytes);
  if (image == null) throw CoverImageException();

  final longSide = image.width > image.height ? image.width : image.height;
  final tooLarge = longSide > coverMaxSide || bytes.length > coverMaxBytes;
  if (autoResize && tooLarge) {
    final resized = longSide > coverMaxSide ? _fit(image, coverMaxSide) : image;
    return ProcessedCover(
      bytes: img.encodeJpg(_flatten(resized), quality: 85),
      mimeType: 'image/jpeg',
      thumbnail: _thumbnailOf(resized),
      width: resized.width,
      height: resized.height,
      resized: true,
    );
  }
  // 読めても一般的でない形式（TIFF など）は、どの環境でも表示できる形式に変換して保存する
  if (mimeTypeOf(bytes) == null) {
    return ProcessedCover(
      bytes: image.hasAlpha ? img.encodePng(image) : img.encodeJpg(image, quality: 90),
      mimeType: image.hasAlpha ? 'image/png' : 'image/jpeg',
      thumbnail: _thumbnailOf(image),
      width: image.width,
      height: image.height,
      resized: false,
    );
  }
  return ProcessedCover(
    bytes: bytes,
    mimeType: mimeTypeOf(bytes)!,
    thumbnail: _thumbnailOf(image),
    width: image.width,
    height: image.height,
    resized: false,
  );
}

/// 画像データの先頭バイトから MIME タイプを判定する。
String? mimeTypeOf(Uint8List bytes) {
  return switch (img.findFormatForData(bytes)) {
    img.ImageFormat.jpg => 'image/jpeg',
    img.ImageFormat.png => 'image/png',
    img.ImageFormat.gif => 'image/gif',
    img.ImageFormat.webp => 'image/webp',
    img.ImageFormat.bmp => 'image/bmp',
    _ => null,
  };
}

/// MIME タイプに対応する拡張子（エクスポートのファイル名用）。
String extensionOfMime(String? mimeType) => switch (mimeType) {
      'image/png' => 'png',
      'image/gif' => 'gif',
      'image/webp' => 'webp',
      'image/bmp' => 'bmp',
      _ => 'jpg',
    };

img.Image? _decode(Uint8List bytes) {
  try {
    final image = img.decodeImage(bytes);
    // 撮影時の向き情報（EXIF）を反映しておかないと、縮小後に横倒しになる。
    return image == null ? null : img.bakeOrientation(image);
  } catch (_) {
    return null;
  }
}

img.Image _fit(img.Image image, int maxSide) {
  if (image.width >= image.height) {
    return img.copyResize(image, width: maxSide, interpolation: img.Interpolation.average);
  }
  return img.copyResize(image, height: maxSide, interpolation: img.Interpolation.average);
}

Uint8List _thumbnailOf(img.Image image) {
  final longSide = image.width > image.height ? image.width : image.height;
  final small = longSide > thumbnailSide ? _fit(image, thumbnailSide) : image;
  return img.encodeJpg(_flatten(small), quality: 80);
}

/// JPEG は透過を持てないため、透過部分を白で塗ってから変換する。
img.Image _flatten(img.Image image) {
  if (!image.hasAlpha) return image;
  final canvas = img.Image(width: image.width, height: image.height);
  img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
  return img.compositeImage(canvas, image);
}
