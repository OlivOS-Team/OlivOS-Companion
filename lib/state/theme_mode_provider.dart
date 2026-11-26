import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../data/settings_store.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) => SettingsStore());

/// Overridden in main after loading the persisted preference.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> toggle(Brightness currentBrightness) async {
    final next = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    state = next;
    try {
      await ref.read(settingsStoreProvider).saveThemeMode(next);
    } catch (_) {
      // The visual switch should still work if persistence is unavailable.
    }
  }
}
