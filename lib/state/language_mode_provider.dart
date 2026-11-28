import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_language.dart';
import 'theme_mode_provider.dart';

/// Overridden in main after loading the persisted preference.
final initialAppLanguageProvider = Provider<AppLanguage>(
  (ref) => AppLanguage.system,
);

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => ref.watch(initialAppLanguageProvider);

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    try {
      await ref.read(settingsStoreProvider).saveAppLanguage(language);
    } catch (_) {
      // The language switch should still work if persistence is unavailable.
    }
  }
}
