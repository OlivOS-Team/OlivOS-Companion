import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-scoped Easter egg state. It intentionally resets when the app exits.
final easterEggModeProvider = NotifierProvider<EasterEggMode, bool>(
  EasterEggMode.new,
);

class EasterEggMode extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
}
