import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps the native window title bar in sync with the Flutter theme.
class WindowThemeService {
  static const _channel = MethodChannel('olivos_companion/window');
  static bool? _lastDark;

  static Future<int?> refreshRate() async {
    try {
      final hz = await _channel.invokeMethod<int>('getRefreshRate');
      if (hz == null || hz <= 1) return null;
      return hz;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setDark(bool dark) async {
    if ((!Platform.isWindows && !Platform.isMacOS) || _lastDark == dark) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('setTitleBarTheme', dark);
      _lastDark = dark;
    } catch (_) {
      // The window may be unavailable during shutdown.
    }
  }

  static Future<void> setLaunchSplashActive(bool active) async {
    if (!Platform.isWindows && !Platform.isMacOS) return;
    try {
      await _channel.invokeMethod<void>('setLaunchSplashActive', active);
    } catch (_) {
      // The window may be unavailable during shutdown.
    }
  }
}
