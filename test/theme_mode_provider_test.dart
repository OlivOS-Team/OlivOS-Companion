import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/data/settings_store.dart';
import 'package:olivos_companion/state/theme_mode_provider.dart';

class _MemorySettingsStore extends SettingsStore {
  ThemeMode? savedMode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    savedMode = mode;
  }
}

void main() {
  test('主题切换会更新状态并持久化', () async {
    final settings = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        initialThemeModeProvider.overrideWithValue(ThemeMode.light),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);
    final notifier = container.read(themeModeProvider.notifier);

    await notifier.setThemeMode(ThemeMode.dark);
    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(settings.savedMode, ThemeMode.dark);

    await notifier.toggle(Brightness.dark);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(settings.savedMode, ThemeMode.light);
  });

  test('设置相同主题不会重复持久化', () async {
    final settings = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        initialThemeModeProvider.overrideWithValue(ThemeMode.dark),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.dark);
    expect(settings.savedMode, isNull);
  });
}
