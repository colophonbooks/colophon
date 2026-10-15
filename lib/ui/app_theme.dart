import 'package:flutter/material.dart';

import '../models/book.dart';
import '../state/settings_controller.dart';

/// ステータス表示1種類分の色。
@immutable
class StatusColor {
  const StatusColor(this.background, this.foreground);

  final Color background;
  final Color foreground;

  static StatusColor lerp(StatusColor a, StatusColor b, double t) => StatusColor(
        Color.lerp(a.background, b.background, t)!,
        Color.lerp(a.foreground, b.foreground, t)!,
      );
}

/// ステータス表示の色。テーマごとに決め、[ThemeData.extensions] で画面へ渡す。
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.unset,
    required this.unread,
    required this.reading,
    required this.finished,
  });

  /// 配色の元になる色から作る（レザー・フォレスト・オーシャン・ローズ）。
  factory StatusColors.fromScheme(ColorScheme s) => StatusColors(
        unset: StatusColor(s.surfaceContainerHighest, s.onSurfaceVariant),
        unread: StatusColor(s.secondaryContainer, s.onSecondaryContainer),
        reading: StatusColor(s.primaryContainer, s.onPrimaryContainer),
        finished: StatusColor(s.tertiaryContainer, s.onTertiaryContainer),
      );

  final StatusColor unset;
  final StatusColor unread;
  final StatusColor reading;
  final StatusColor finished;

  StatusColor of(ReadingStatus status) => switch (status) {
        ReadingStatus.unset => unset,
        ReadingStatus.unread => unread,
        ReadingStatus.reading => reading,
        ReadingStatus.finished => finished,
      };

  @override
  StatusColors copyWith({
    StatusColor? unset,
    StatusColor? unread,
    StatusColor? reading,
    StatusColor? finished,
  }) =>
      StatusColors(
        unset: unset ?? this.unset,
        unread: unread ?? this.unread,
        reading: reading ?? this.reading,
        finished: finished ?? this.finished,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      unset: StatusColor.lerp(unset, other.unset, t),
      unread: StatusColor.lerp(unread, other.unread, t),
      reading: StatusColor.lerp(reading, other.reading, t),
      finished: StatusColor.lerp(finished, other.finished, t),
    );
  }
}

/// テーマと明暗から ThemeData を作る。
ThemeData buildTheme(ColorThemeId id, Brightness brightness) {
  final scheme = colorSchemeFor(id, brightness);
  return ThemeData(
    colorScheme: scheme,
    extensions: [statusColorsFor(id, brightness, scheme)],
  );
}

ColorScheme colorSchemeFor(ColorThemeId id, Brightness brightness) {
  ColorScheme seeded(int seed, [DynamicSchemeVariant variant = DynamicSchemeVariant.tonalSpot]) =>
      ColorScheme.fromSeed(seedColor: Color(seed), brightness: brightness, dynamicSchemeVariant: variant);

  return switch (id) {
    ColorThemeId.leather => seeded(0xFF7B5536),
    ColorThemeId.forest => seeded(0xFF2F6B4F),
    ColorThemeId.ocean => seeded(0xFF1F4E79),
    ColorThemeId.rose => seeded(0xFF8E3B5E),
    ColorThemeId.monochrome => _monochromeScheme(brightness),
    // CUD 推奨配色セットの青を基準にする。fidelity は基準色を主色にほぼそのまま使う
    ColorThemeId.universal => seeded(0xFF005AFF, DynamicSchemeVariant.fidelity),
  };
}

/// 白黒（グレーのみ）。monochrome 変種でもエラー色だけは赤のまま残るため、グレーに置き換える。
ColorScheme _monochromeScheme(Brightness brightness) {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFF808080),
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
  );
  final light = brightness == Brightness.light;
  return base.copyWith(
    error: light ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
    onError: light ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
    errorContainer: light ? const Color(0xFFD9D9D9) : const Color(0xFF3B3B3B),
    onErrorContainer: light ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
  );
}

StatusColors statusColorsFor(ColorThemeId id, Brightness brightness, ColorScheme scheme) {
  final light = brightness == Brightness.light;
  return switch (id) {
    // 4段階の明るさで区別する（隣り合う段階の色差 ΔE ≥ 20。アイコンと文字も併記）
    ColorThemeId.monochrome => light
        ? const StatusColors(
            unset: StatusColor(Color(0xFFF2F2F2), Color(0xFF303030)),
            unread: StatusColor(Color(0xFFB3B3B3), Color(0xFF000000)),
            reading: StatusColor(Color(0xFF737373), Color(0xFFFFFFFF)),
            finished: StatusColor(Color(0xFF1E1E1E), Color(0xFFFFFFFF)),
          )
        : const StatusColors(
            unset: StatusColor(Color(0xFF2C2C2C), Color(0xFFE0E0E0)),
            unread: StatusColor(Color(0xFF5E5E5E), Color(0xFFFFFFFF)),
            reading: StatusColor(Color(0xFF9E9E9E), Color(0xFF000000)),
            finished: StatusColor(Color(0xFFEDEDED), Color(0xFF000000)),
          ),
    // カラーユニバーサルデザイン推奨配色セットの青系・オレンジ系を使い、
    // 赤と緑の区別に頼らない。明るさにも差を付けて、どの色覚でも見分けられるようにする
    ColorThemeId.universal => light
        ? const StatusColors(
            unset: StatusColor(Color(0xFFE6E6E6), Color(0xFF333333)),
            unread: StatusColor(Color(0xFF4DC4FF), Color(0xFF00205C)),
            reading: StatusColor(Color(0xFFF6AA00), Color(0xFF2B1A00)),
            finished: StatusColor(Color(0xFF005AFF), Color(0xFFFFFFFF)),
          )
        : const StatusColors(
            unset: StatusColor(Color(0xFF3A3A3A), Color(0xFFE6E6E6)),
            unread: StatusColor(Color(0xFF0B3D91), Color(0xFFDDEEFF)),
            reading: StatusColor(Color(0xFFF6AA00), Color(0xFF1A1000)),
            finished: StatusColor(Color(0xFF4DC4FF), Color(0xFF001A33)),
          ),
    _ => StatusColors.fromScheme(scheme),
  };
}

/// ステータスのアイコン。色に頼らずに区別できるようにする。
IconData statusIcon(ReadingStatus status) => switch (status) {
      ReadingStatus.unset => Icons.radio_button_unchecked,
      ReadingStatus.unread => Icons.book_outlined,
      ReadingStatus.reading => Icons.bookmark,
      ReadingStatus.finished => Icons.check_circle,
    };
