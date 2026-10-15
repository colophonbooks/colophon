import 'package:colophon/data/book_repository.dart';
import 'package:colophon/state/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('初回は既定値になる', () async {
    SharedPreferences.setMockInitialValues({});
    final s = SettingsController(await SharedPreferences.getInstance());
    expect(s.hasChosenLanguage, isFalse);
    expect(s.autoResize, isTrue);
    expect(s.gridView, isFalse);
    expect(s.sort, BookSort.recent);
    expect(s.colorTheme, ColorThemeId.leather);
    expect(s.themeMode, ThemeMode.system);
    expect(s.exportTextWithCovers, isFalse);
  });

  test('変更した設定は保存され、次に起動したときに読み込まれる', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsController(prefs);
    await s.setLanguage('fr');
    await s.setAutoResize(false);
    await s.setGridView(true);
    await s.setSort(BookSort.title);
    await s.setColorTheme(ColorThemeId.universal);
    await s.setThemeMode(ThemeMode.dark);
    await s.setExportTextWithCovers(true);

    final reloaded = SettingsController(prefs);
    expect(reloaded.locale, const Locale('fr'));
    expect(reloaded.autoResize, isFalse);
    expect(reloaded.gridView, isTrue);
    expect(reloaded.sort, BookSort.title);
    expect(reloaded.colorTheme, ColorThemeId.universal);
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.exportTextWithCovers, isTrue);
  });

  test('すべて初期化すると、保存値も消えて言語選択からやり直しになる', () async {
    SharedPreferences.setMockInitialValues({'language': 'ja', 'colorTheme': 'rose', 'gridView': true});
    final prefs = await SharedPreferences.getInstance();
    final s = SettingsController(prefs);

    await s.resetAll();

    expect(s.hasChosenLanguage, isFalse);
    expect(s.colorTheme, ColorThemeId.leather);
    expect(s.gridView, isFalse);
    expect(prefs.getKeys(), isEmpty);
  });

  test('保存値が壊れていても既定値で起動する', () async {
    SharedPreferences.setMockInitialValues({'sort': 'xxx', 'colorTheme': 'unknown', 'themeMode': '???'});
    final s = SettingsController(await SharedPreferences.getInstance());
    expect(s.sort, BookSort.recent);
    expect(s.colorTheme, ColorThemeId.leather);
    expect(s.themeMode, ThemeMode.system);
  });
}
