import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  static const supportedLocales = <Locale>[Locale('zh', 'CN'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Localizations.localeOf(context));
  }

  bool get _isEnglish => locale.languageCode == 'en';

  String easterEggTapsRemaining(int remaining) {
    if (_isEnglish) {
      return switch (remaining) {
        5 => '5 taps to go',
        4 => 'Developer mode is warming up — 4 taps to go',
        3 => 'lunzhiPenxil is counting behind the door — 3 taps to go',
        2 => 'A bosom friend afar brings a distant land near. 2 taps to go',
        1 => 'The Sword Pavilion stands steep and towering — 1 tap to go',
        _ => '$remaining taps to go',
      };
    }
    return switch (remaining) {
      5 => '还差 5 次',
      4 => '开发者模式正在热身，还差 4 次',
      3 => '仑质在门后数数，还差 3 次',
      2 => '海内存知己，天涯若比邻。还差 2 次',
      1 => '剑阁峥嵘而崔嵬，还差 1 次',
      _ => '还差 $remaining 次',
    };
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
