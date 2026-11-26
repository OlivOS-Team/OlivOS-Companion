import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/data/settings_store.dart';

void main() {
  test('默认主题为跟随系统', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final store = SettingsStore(dataDirectory: directory);
    expect(await store.loadThemeMode(), ThemeMode.system);
  });

  test('主题设置可持久化', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final store = SettingsStore(dataDirectory: directory);
    await store.saveThemeMode(ThemeMode.dark);
    expect(await store.loadThemeMode(), ThemeMode.dark);

    await store.saveThemeMode(ThemeMode.light);
    expect(await store.loadThemeMode(), ThemeMode.light);
  });
}
