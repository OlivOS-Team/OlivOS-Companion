import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/theme.dart';
import 'core/app_paths.dart';
import 'core/window_theme_service.dart';
import 'data/settings_store.dart';
import 'features/instances/instance_list_page.dart';
import 'features/startup/launch_gate.dart';
import 'l10n/app_localizations.dart';
import 'models/app_language.dart';
import 'state/language_mode_provider.dart';
import 'state/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPaths.initialize();

  final settingsStore = SettingsStore();
  final initialThemeMode = await settingsStore.loadThemeMode();
  final initialAppLanguage = await settingsStore.loadAppLanguage();
  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(settingsStore),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
        initialAppLanguageProvider.overrideWithValue(initialAppLanguage),
      ],
      child: const OlivOSCompanionApp(),
    ),
  );
}

class OlivOSCompanionApp extends ConsumerWidget {
  const OlivOSCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: 'OlivOS Companion',
      debugShowCheckedModeBanner: false,
      locale: switch (appLanguage) {
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
      themeMode: ref.watch(themeModeProvider),
      home: const _TitleBarThemeSync(
        child: LaunchGate(child: InstanceListPage()),
      ),
    );
  }
}

/// Keeps desktop window chrome and mobile system bars in sync with the theme.
class _TitleBarThemeSync extends StatefulWidget {
  const _TitleBarThemeSync({required this.child});

  final Widget child;

  @override
  State<_TitleBarThemeSync> createState() => _TitleBarThemeSyncState();
}

class _TitleBarThemeSyncState extends State<_TitleBarThemeSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarDividerColor: scheme.surface,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
    unawaited(WindowThemeService.setDark(dark));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
