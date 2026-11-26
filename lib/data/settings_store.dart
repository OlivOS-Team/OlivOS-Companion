import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

import '../core/app_paths.dart';

class SettingsStore {
  SettingsStore({this.dataDirectory});

  static const _fileName = 'settings.json';
  static const _themeModeKey = 'themeMode';

  final Directory? dataDirectory;

  Future<File> _settingsFile() async {
    final directory = dataDirectory ?? await AppPaths.dataDirectory();
    return File(p.join(directory.path, _fileName));
  }

  Future<ThemeMode> loadThemeMode() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) return ThemeMode.system;

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return ThemeMode.system;
      return switch (decoded[_themeModeKey]) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final file = await _settingsFile();
    Map<String, dynamic> settings = {};
    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          settings = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Replace a damaged settings file with a valid one.
      }
    }

    settings[_themeModeKey] = mode.name;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings), flush: true);
  }
}
