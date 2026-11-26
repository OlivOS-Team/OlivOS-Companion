import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Resolves the data directories for the current installation mode.
///
/// Installer builds use the standard per-user application support directory.
/// Portable builds (identified by `portable.flag` next to the executable) keep
/// their data beside the executable in `userdata/`.
class AppPaths {
  static const String portableMarkerName = 'portable.flag';
  static const String _portableDataDirectoryName = 'userdata';
  static const String _companyName = 'com.olivosteam';
  static const String _productName = 'olivos_companion';

  static Directory? _dataDirectory;
  static bool _portable = false;
  static bool _initialized = false;

  static bool get isPortable => _portable;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final executableDirectory = File(Platform.resolvedExecutable).parent;
    _portable =
        Platform.isWindows &&
        File(p.join(executableDirectory.path, portableMarkerName)).existsSync();

    if (_portable) {
      final dataDirectory = Directory(
        p.join(executableDirectory.path, _portableDataDirectoryName),
      );
      await dataDirectory.create(recursive: true);
      _dataDirectory = dataDirectory;

      // flutter_secure_storage resolves its DPAPI file through path_provider.
      // Redirect that lookup to the portable data directory before the first
      // secure-storage access.
      final fallback = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _PortablePathProvider(
        fallback,
        dataDirectory.path,
      );
      return;
    }

    final dataDirectory = await getApplicationSupportDirectory();
    await dataDirectory.create(recursive: true);
    _dataDirectory = dataDirectory;
  }

  static Future<Directory> dataDirectory() async {
    await initialize();
    return _dataDirectory!;
  }

  static Future<Directory?> webView2Directory() async {
    if (!Platform.isWindows) return null;

    if (_portable) {
      return Directory(p.join((await dataDirectory()).path, 'WebView2'));
    }

    // WebView2 must not use the read-only install directory for an installed
    // app. Keep its profile in LocalAppData instead of the roaming app data
    // used for settings and credentials.
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final baseDirectory = localAppData != null && localAppData.isNotEmpty
        ? Directory(p.join(localAppData, _companyName, _productName))
        : await dataDirectory();
    return Directory(p.join(baseDirectory.path, 'WebView2'));
  }
}

class _PortablePathProvider extends PathProviderPlatform {
  _PortablePathProvider(this._fallback, this._applicationSupportPath);

  final PathProviderPlatform _fallback;
  final String _applicationSupportPath;

  @override
  Future<String?> getApplicationSupportPath() async => _applicationSupportPath;

  @override
  Future<String?> getTemporaryPath() => _fallback.getTemporaryPath();

  @override
  Future<String?> getLibraryPath() => _fallback.getLibraryPath();

  @override
  Future<String?> getApplicationDocumentsPath() =>
      _fallback.getApplicationDocumentsPath();

  @override
  Future<String?> getApplicationCachePath() =>
      _fallback.getApplicationCachePath();

  @override
  Future<String?> getExternalStoragePath() =>
      _fallback.getExternalStoragePath();

  @override
  Future<List<String>?> getExternalCachePaths() =>
      _fallback.getExternalCachePaths();

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) =>
      _fallback.getExternalStoragePaths(type: type);

  @override
  Future<String?> getDownloadsPath() => _fallback.getDownloadsPath();
}
