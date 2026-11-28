import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:olivos_companion/app/theme.dart';
import 'package:olivos_companion/data/settings_store.dart';
import 'package:olivos_companion/features/instances/instance_list_page.dart';
import 'package:olivos_companion/l10n/app_localizations.dart';
import 'package:olivos_companion/models/app_language.dart';
import 'package:olivos_companion/state/instances_provider.dart';
import 'package:olivos_companion/state/language_mode_provider.dart';
import 'package:olivos_companion/state/theme_mode_provider.dart';

import 'support/memory_instance_store.dart';

class _MemorySettingsStore extends SettingsStore {
  AppLanguage? savedLanguage;

  @override
  Future<void> saveAppLanguage(AppLanguage language) async {
    savedLanguage = language;
  }
}

Widget _app(MemoryInstanceStore instances, SettingsStore settings) {
  return ProviderScope(
    overrides: [
      instanceStoreProvider.overrideWithValue(instances),
      settingsStoreProvider.overrideWithValue(settings),
      initialAppLanguageProvider.overrideWithValue(AppLanguage.chinese),
    ],
    child: Consumer(
      builder: (context, ref, child) {
        final language = ref.watch(appLanguageProvider);
        return MaterialApp(
          locale: switch (language) {
            AppLanguage.system => null,
            AppLanguage.chinese => const Locale('zh', 'CN'),
            AppLanguage.english => const Locale('en'),
          },
          supportedLocales: AppLocalizations.supportedLocales,
          localeListResolutionCallback: (locales, supportedLocales) =>
              AppLocalizations.resolveSystemLocale(locales),
          localizationsDelegates: [
            ...GlobalMaterialLocalizations.delegates,
            AppLocalizations.delegate,
          ],
          theme: buildOlivOSTheme(Brightness.light),
          darkTheme: buildOlivOSTheme(Brightness.dark),
          themeMode: ThemeMode.light,
          home: const InstanceListPage(),
        );
      },
    ),
  );
}

void main() {
  testWidgets('更多菜单的语言选项切换界面语言并持久化', (tester) async {
    final settings = _MemorySettingsStore();
    await tester.pumpWidget(_app(MemoryInstanceStore(), settings));
    await tester.pumpAndSettle();

    expect(find.text('还没有 OlivOS 实例'), findsOneWidget);
    expect(find.text('Witness Union / 见证联合'), findsOneWidget);

    await tester.tap(find.byKey(const Key('more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-english')));
    await tester.pumpAndSettle();

    expect(find.text('No OlivOS instances yet'), findsOneWidget);
    expect(find.text('Add instance'), findsOneWidget);
    expect(find.text('Witness Union / 见证联合'), findsOneWidget);
    expect(settings.savedLanguage, AppLanguage.english);
  });
}
