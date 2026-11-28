import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/data/settings_store.dart';
import 'package:olivos_companion/models/app_language.dart';

void main() {
  test('默认主题为跟随系统', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final store = SettingsStore(dataDirectory: directory);
    expect(await store.loadThemeMode(), ThemeMode.system);
  });

  test('默认语言为跟随系统', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final store = SettingsStore(dataDirectory: directory);
    expect(await store.loadAppLanguage(), AppLanguage.system);
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

  test('语言设置可持久化且不覆盖主题设置', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-settings-');
    addTearDown(() => directory.delete(recursive: true));

    final store = SettingsStore(dataDirectory: directory);
    await store.saveThemeMode(ThemeMode.dark);
    await store.saveAppLanguage(AppLanguage.english);

    expect(await store.loadAppLanguage(), AppLanguage.english);
    expect(await store.loadThemeMode(), ThemeMode.dark);

    await store.saveAppLanguage(AppLanguage.chinese);
    expect(await store.loadAppLanguage(), AppLanguage.chinese);
    expect(await store.loadThemeMode(), ThemeMode.dark);
  });
}
