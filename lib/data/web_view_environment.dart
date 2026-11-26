import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../core/app_paths.dart';

/// Creates one shared WebView2 environment with an app-owned profile path.
class WebViewEnvironmentService {
  static Future<WebViewEnvironment?>? _environment;

  static Future<WebViewEnvironment?> ensure() {
    if (!Platform.isWindows) return Future<WebViewEnvironment?>.value();
    return _environment ??= _create();
  }

  static Future<WebViewEnvironment?> _create() async {
    try {
      final directory = await AppPaths.webView2Directory();
      if (directory == null) return null;
      await directory.create(recursive: true);

      return await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(userDataFolder: directory.path),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to create WebViewEnvironment: $error\n$stackTrace');
      return null;
    }
  }
}
