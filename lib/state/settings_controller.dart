import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/book_repository.dart';

/// 選択できる表示言語。言語を増やすときは ARB ファイルを追加し、ここに1行足す。
/// 名前は各言語自身の表記にする（どの言語で表示中でも読めるように）。
const supportedLanguages = <({String code, String name})>[
  (code: 'en', name: 'English'),
  (code: 'ja', name: '日本語'),
  (code: 'zh', name: '简体中文'),
  (code: 'fr', name: 'Français'),
  (code: 'es', name: 'Español'),
  (code: 'de', name: 'Deutsch'),
  (code: 'ko', name: '한국어'),
];

/// 配色テーマ。保存には [name] を使う。並び順は設定画面の表示順。
enum ColorThemeId { leather, forest, ocean, rose, monochrome, universal }

/// ユーザー設定（端末ごとに保存し、エクスポートには含めない）。
class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs)
      : _languageCode = _prefs.getString(_kLanguage),
        _autoResize = _prefs.getBool(_kAutoResize) ?? true,
        _gridView = _prefs.getBool(_kGridView) ?? false,
        _sort = BookSort.values.asNameMap()[_prefs.getString(_kSort)] ?? BookSort.recent,
        _colorTheme =
            ColorThemeId.values.asNameMap()[_prefs.getString(_kColorTheme)] ?? ColorThemeId.leather,
        _themeMode = ThemeMode.values.asNameMap()[_prefs.getString(_kThemeMode)] ?? ThemeMode.system,
        _exportTextWithCovers = _prefs.getBool(_kExportTextWithCovers) ?? false;

  static const _kLanguage = 'language';
  static const _kAutoResize = 'autoResizeCover';
  static const _kGridView = 'gridView';
  static const _kSort = 'sort';
  static const _kColorTheme = 'colorTheme';
  static const _kThemeMode = 'themeMode';
  static const _kExportTextWithCovers = 'exportTextWithCovers';

  final SharedPreferences _prefs;
  String? _languageCode;
  String? _previewLanguageCode;
  bool _autoResize;
  bool _gridView;
  BookSort _sort;
  ColorThemeId _colorTheme;
  ThemeMode _themeMode;
  bool _exportTextWithCovers;

  /// 初回起動の言語選択を済ませたか。
  bool get hasChosenLanguage => _languageCode != null;

  /// 画面に使う言語。初回の言語選択中は、選びかけの言語を表示に反映する。
  Locale? get locale {
    final code = _previewLanguageCode ?? _languageCode;
    return code == null ? null : Locale(code);
  }

  bool get autoResize => _autoResize;
  bool get gridView => _gridView;
  BookSort get sort => _sort;
  ColorThemeId get colorTheme => _colorTheme;

  /// 明るさ（OSに合わせる／明るい／暗い）。
  ThemeMode get themeMode => _themeMode;

  /// テキストのエクスポートに書影を含めるか（前回の選択）。
  bool get exportTextWithCovers => _exportTextWithCovers;

  /// 端末の言語が対応言語ならそれを、なければ英語を初期候補にする。
  static String initialLanguageFor(Locale deviceLocale) {
    final code = deviceLocale.languageCode;
    return supportedLanguages.any((l) => l.code == code) ? code : 'en';
  }

  void previewLanguage(String code) {
    _previewLanguageCode = code;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    _previewLanguageCode = null;
    notifyListeners();
    await _prefs.setString(_kLanguage, code);
  }

  Future<void> setAutoResize(bool value) async {
    _autoResize = value;
    notifyListeners();
    await _prefs.setBool(_kAutoResize, value);
  }

  Future<void> setGridView(bool value) async {
    _gridView = value;
    notifyListeners();
    await _prefs.setBool(_kGridView, value);
  }

  Future<void> setSort(BookSort value) async {
    _sort = value;
    notifyListeners();
    await _prefs.setString(_kSort, value.name);
  }

  Future<void> setColorTheme(ColorThemeId value) async {
    _colorTheme = value;
    notifyListeners();
    await _prefs.setString(_kColorTheme, value.name);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    await _prefs.setString(_kThemeMode, value.name);
  }

  /// すべての設定を消して初期状態に戻す（表示言語も未選択に戻り、言語選択画面から始まる）。
  Future<void> resetAll() async {
    await _prefs.clear();
    _languageCode = null;
    _previewLanguageCode = null;
    _autoResize = true;
    _gridView = false;
    _sort = BookSort.recent;
    _colorTheme = ColorThemeId.leather;
    _themeMode = ThemeMode.system;
    _exportTextWithCovers = false;
    notifyListeners();
  }

  Future<void> setExportTextWithCovers(bool value) async {
    _exportTextWithCovers = value;
    notifyListeners();
    await _prefs.setBool(_kExportTextWithCovers, value);
  }
}
