import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/theme.dart';
import 'core/app_paths.dart';
import 'data/settings_store.dart';
import 'features/instances/instance_list_page.dart';
import 'state/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPaths.initialize();

  final settingsStore = SettingsStore();
  final initialThemeMode = await settingsStore.loadThemeMode();
  runApp(
    ProviderScope(
      overrides: [
        settingsStoreProvider.overrideWithValue(settingsStore),
        initialThemeModeProvider.overrideWithValue(initialThemeMode),
      ],
      child: const OlivOSCompanionApp(),
    ),
  );
}

class OlivOSCompanionApp extends ConsumerWidget {
  const OlivOSCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'OlivOS Companion',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildOlivOSTheme(Brightness.light),
      darkTheme: buildOlivOSTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      home: const InstanceListPage(),
    );
  }
}
