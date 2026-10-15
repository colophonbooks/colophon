import 'dart:math' as math;

import 'package:colophon/models/book.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:colophon/ui/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// 色の計算（WCAG のコントラスト比、色覚シミュレーション、CIELAB の色差）
// ---------------------------------------------------------------------------

double _toLinear(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _toSrgb(double c) {
  final v = c.clamp(0.0, 1.0);
  return v <= 0.0031308 ? v * 12.92 : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
}

List<double> _linearRgb(Color c) => [_toLinear(c.r), _toLinear(c.g), _toLinear(c.b)];

/// WCAG 2.x のコントラスト比。
double contrastRatio(Color a, Color b) {
  double lum(Color c) {
    final l = _linearRgb(c);
    return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2];
  }

  final la = lum(a), lb = lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Machado, Oliveira & Fernandes (2009) の色覚シミュレーション行列（重度 1.0）。
const _cvdMatrices = {
  'protan（P型）': [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  'deutan（D型）': [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ],
  'tritan（T型）': [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ],
};

Color simulate(Color c, List<List<double>> m) {
  final l = _linearRgb(c);
  double ch(int i) => _toSrgb(m[i][0] * l[0] + m[i][1] * l[1] + m[i][2] * l[2]);
  return Color.from(alpha: 1, red: ch(0), green: ch(1), blue: ch(2));
}

/// CIELAB（D65）。
List<double> lab(Color c) {
  final l = _linearRgb(c);
  final x = (0.4124 * l[0] + 0.3576 * l[1] + 0.1805 * l[2]) / 0.95047;
  final y = 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2];
  final z = (0.0193 * l[0] + 0.1192 * l[1] + 0.9505 * l[2]) / 1.08883;
  double f(double t) => t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

/// CIE76 の色差 ΔE。20 以上なら一目で別の色と分かる程度。
double deltaE(Color a, Color b) {
  final p = lab(a), q = lab(b);
  return math.sqrt(math.pow(p[0] - q[0], 2) + math.pow(p[1] - q[1], 2) + math.pow(p[2] - q[2], 2));
}

bool isGray(Color c) => (c.r - c.g).abs() < 1e-9 && (c.g - c.b).abs() < 1e-9;

// ---------------------------------------------------------------------------

void main() {
  const brightnesses = [Brightness.light, Brightness.dark];

  group('全テーマ・明暗の文字と背景のコントラストが WCAG AA（4.5:1）以上', () {
    for (final id in ColorThemeId.values) {
      for (final b in brightnesses) {
        test('${id.name} / ${b.name}', () {
          final scheme = colorSchemeFor(id, b);
          final status = statusColorsFor(id, b, scheme);
          final pairs = {
            'onSurface/surface': (scheme.onSurface, scheme.surface),
            'onSurfaceVariant/surface': (scheme.onSurfaceVariant, scheme.surface),
            'onPrimary/primary': (scheme.onPrimary, scheme.primary),
            'onPrimaryContainer/primaryContainer': (scheme.onPrimaryContainer, scheme.primaryContainer),
            'onError/error': (scheme.onError, scheme.error),
            'error/surface': (scheme.error, scheme.surface),
            for (final s in ReadingStatus.values)
              'status ${s.name}': (status.of(s).foreground, status.of(s).background),
          };
          for (final e in pairs.entries) {
            final ratio = contrastRatio(e.value.$1, e.value.$2);
            expect(ratio, greaterThanOrEqualTo(4.5), reason: '${e.key}: ${ratio.toStringAsFixed(2)}');
          }
        });
      }
    }
  });

  group('モノクロテーマはグレーだけでできている', () {
    for (final b in brightnesses) {
      test(b.name, () {
        final s = colorSchemeFor(ColorThemeId.monochrome, b);
        final colors = {
          'primary': s.primary, 'onPrimary': s.onPrimary,
          'primaryContainer': s.primaryContainer, 'onPrimaryContainer': s.onPrimaryContainer,
          'secondary': s.secondary, 'secondaryContainer': s.secondaryContainer,
          'tertiary': s.tertiary, 'tertiaryContainer': s.tertiaryContainer,
          'error': s.error, 'onError': s.onError,
          'errorContainer': s.errorContainer, 'onErrorContainer': s.onErrorContainer,
          'surface': s.surface, 'onSurface': s.onSurface,
          'surfaceContainerHighest': s.surfaceContainerHighest, 'onSurfaceVariant': s.onSurfaceVariant,
          'outline': s.outline, 'outlineVariant': s.outlineVariant,
          'inverseSurface': s.inverseSurface, 'inversePrimary': s.inversePrimary,
        };
        final status = statusColorsFor(ColorThemeId.monochrome, b, s);
        for (final st in ReadingStatus.values) {
          colors['status ${st.name} bg'] = status.of(st).background;
          colors['status ${st.name} fg'] = status.of(st).foreground;
        }
        for (final e in colors.entries) {
          expect(isGray(e.value), isTrue, reason: '${e.key} = ${e.value}');
        }
      });
    }
  });

  group('ステータスの色は、色覚の違いにかかわらず見分けられる（ΔE ≥ 20）', () {
    final targets = [ColorThemeId.universal, ColorThemeId.monochrome];
    final visions = <String, Color Function(Color)>{
      '一般色覚': (c) => c,
      for (final e in _cvdMatrices.entries) e.key: (c) => simulate(c, e.value),
    };
    for (final id in targets) {
      for (final b in brightnesses) {
        for (final v in visions.entries) {
          test('${id.name} / ${b.name} / ${v.key}', () {
            final status = statusColorsFor(id, b, colorSchemeFor(id, b));
            final all = ReadingStatus.values;
            for (var i = 0; i < all.length; i++) {
              for (var j = i + 1; j < all.length; j++) {
                final d = deltaE(v.value(status.of(all[i]).background), v.value(status.of(all[j]).background));
                expect(d, greaterThanOrEqualTo(20),
                    reason: '${all[i].name} と ${all[j].name}: ΔE ${d.toStringAsFixed(1)}');
              }
            }
          });
        }
      }
    }
  });

  test('すべてのステータスに別々のアイコンがある', () {
    final icons = ReadingStatus.values.map(statusIcon).toSet();
    expect(icons, hasLength(ReadingStatus.values.length));
  });
}
