import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../core/app_paths.dart';
import '../models/app_language.dart';

class SettingsStore {
  SettingsStore({this.dataDirectory});

  static const _fileName = 'settings.json';
  static const _themeModeKey = 'themeMode';
  static const _languageKey = 'language';

  final Directory? dataDirectory;

  Future<File> _settingsFile() async {
    final directory = dataDirectory ?? await AppPaths.dataDirectory();
    return File(p.join(directory.path, _fileName));
  }

  Future<Map<String, dynamic>> _readSettings() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return {};
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic>
          ? Map<String, dynamic>.from(decoded)
          : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeSetting(String key, String value) async {
    final file = await _settingsFile();
    final settings = await _readSettings();
    settings[key] = value;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings), flush: true);
  }

  Future<ThemeMode> loadThemeMode() async {
    final settings = await _readSettings();
    return switch (settings[_themeModeKey]) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _writeSetting(_themeModeKey, mode.name);

  Future<AppLanguage> loadAppLanguage() async {
    final settings = await _readSettings();
    return switch (settings[_languageKey]) {
      'chinese' => AppLanguage.chinese,
      'english' => AppLanguage.english,
      _ => AppLanguage.system,
    };
  }

  Future<void> saveAppLanguage(AppLanguage language) =>
      _writeSetting(_languageKey, language.name);
}
