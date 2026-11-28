import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/settings_store.dart';
import 'package:olivos_companion/models/app_language.dart';
import 'package:olivos_companion/state/language_mode_provider.dart';
import 'package:olivos_companion/state/theme_mode_provider.dart';

class _MemorySettingsStore extends SettingsStore {
  AppLanguage? savedLanguage;

  @override
  Future<void> saveAppLanguage(AppLanguage language) async {
    savedLanguage = language;
  }
}

void main() {
  test('语言切换会更新状态并持久化', () async {
    final settings = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        initialAppLanguageProvider.overrideWithValue(AppLanguage.chinese),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(appLanguageProvider), AppLanguage.chinese);
    await container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.english);

    expect(container.read(appLanguageProvider), AppLanguage.english);
    expect(settings.savedLanguage, AppLanguage.english);
  });

  test('设置相同语言不会重复持久化', () async {
    final settings = _MemorySettingsStore();
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(settings),
        initialAppLanguageProvider.overrideWithValue(AppLanguage.english),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.english);
    expect(settings.savedLanguage, isNull);
  });
}
