import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/core/app_paths.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.supportPath);

  final String? supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;

  @override
  Future<String?> getTemporaryPath() async => 'temp';

  @override
  Future<String?> getLibraryPath() async => 'library';

  @override
  Future<String?> getApplicationDocumentsPath() async => 'documents';

  @override
  Future<String?> getApplicationCachePath() async => 'cache';

  @override
  Future<String?> getExternalStoragePath() async => 'external';

  @override
  Future<List<String>?> getExternalCachePaths() async => ['external-cache'];

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => ['external-${type?.name ?? 'none'}'];

  @override
  Future<String?> getDownloadsPath() async => 'downloads';
}

void main() {
  late PathProviderPlatform originalPathProvider;

  setUp(() {
    originalPathProvider = PathProviderPlatform.instance;
    AppPaths.resetForTesting();
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPathProvider;
    AppPaths.resetForTesting();
  });

  test('便携模式使用 exe 旁的 userdata 和 WebView2 目录', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-paths-');
    addTearDown(() => directory.delete(recursive: true));
    await File(p.join(directory.path, 'portable.flag')).create();
    await File(p.join(directory.path, 'app.exe')).create();

    await AppPaths.initialize(
      environment: AppPathsEnvironment(
        isWindows: true,
        resolvedExecutable: p.join(directory.path, 'app.exe'),
        environment: const {'LOCALAPPDATA': 'ignored'},
        pathProvider: _FakePathProvider(p.join(directory.path, 'support')),
      ),
    );

    expect(AppPaths.isPortable, isTrue);
    expect(
      (await AppPaths.dataDirectory()).path,
      p.join(directory.path, 'userdata'),
    );
    expect(
      await PathProviderPlatform.instance.getApplicationSupportPath(),
      p.join(directory.path, 'userdata'),
    );
    expect(
      (await AppPaths.webView2Directory())?.path,
      p.join(directory.path, 'userdata', 'WebView2'),
    );

    final provider = PathProviderPlatform.instance;
    expect(await provider.getTemporaryPath(), 'temp');
    expect(await provider.getLibraryPath(), 'library');
    expect(await provider.getApplicationDocumentsPath(), 'documents');
    expect(await provider.getApplicationCachePath(), 'cache');
    expect(await provider.getExternalStoragePath(), 'external');
    expect(await provider.getExternalCachePaths(), ['external-cache']);
    expect(
      await provider.getExternalStoragePaths(type: StorageDirectory.downloads),
      ['external-downloads'],
    );
    expect(await provider.getDownloadsPath(), 'downloads');
  });

  test('system 环境读取当前平台信息', () {
    final environment = AppPathsEnvironment.system();
    expect(environment.isWindows, Platform.isWindows);
    expect(environment.resolvedExecutable, Platform.resolvedExecutable);
    expect(environment.environment, Platform.environment);
  });

  test('initialize 只生效一次', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-paths-');
    addTearDown(() => directory.delete(recursive: true));
    final support = p.join(directory.path, 'support');

    final environment = AppPathsEnvironment(
      isWindows: true,
      resolvedExecutable: p.join(directory.path, 'app.exe'),
      environment: const {},
      pathProvider: _FakePathProvider(support),
    );
    await AppPaths.initialize(environment: environment);
    await AppPaths.initialize(
      environment: AppPathsEnvironment(
        isWindows: true,
        resolvedExecutable: p.join(directory.path, 'other.exe'),
        environment: const {},
        pathProvider: _FakePathProvider(p.join(directory.path, 'other')),
      ),
    );

    expect((await AppPaths.dataDirectory()).path, support);
  });

  test('安装版使用应用支持目录和 LOCALAPPDATA 下的 WebView2', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-paths-');
    addTearDown(() => directory.delete(recursive: true));
    final support = p.join(directory.path, 'support');
    final localAppData = p.join(directory.path, 'local');

    await AppPaths.initialize(
      environment: AppPathsEnvironment(
        isWindows: true,
        resolvedExecutable: p.join(directory.path, 'app.exe'),
        environment: {'LOCALAPPDATA': localAppData},
        pathProvider: _FakePathProvider(support),
      ),
    );

    expect(AppPaths.isPortable, isFalse);
    expect((await AppPaths.dataDirectory()).path, support);
    expect(
      (await AppPaths.webView2Directory())?.path,
      p.join(localAppData, 'com.olivosteam', 'olivos_companion', 'WebView2'),
    );
  });

  test('缺少 LOCALAPPDATA 时 WebView2 回退到应用支持目录', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-paths-');
    addTearDown(() => directory.delete(recursive: true));
    final support = p.join(directory.path, 'support');

    await AppPaths.initialize(
      environment: AppPathsEnvironment(
        isWindows: true,
        resolvedExecutable: p.join(directory.path, 'app.exe'),
        environment: const {},
        pathProvider: _FakePathProvider(support),
      ),
    );

    expect(
      (await AppPaths.webView2Directory())?.path,
      p.join(support, 'WebView2'),
    );
  });

  test('非 Windows 平台没有 WebView2 目录', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-paths-');
    addTearDown(() => directory.delete(recursive: true));

    await AppPaths.initialize(
      environment: AppPathsEnvironment(
        isWindows: false,
        resolvedExecutable: p.join(directory.path, 'app'),
        environment: const {},
        pathProvider: _FakePathProvider(p.join(directory.path, 'support')),
      ),
    );

    expect(await AppPaths.webView2Directory(), isNull);
  });

  test('应用支持目录不可用时初始化失败', () async {
    final directory = await Directory.systemTemp.createTemp('olivos-paths-');
    addTearDown(() => directory.delete(recursive: true));

    expect(
      () => AppPaths.initialize(
        environment: AppPathsEnvironment(
          isWindows: true,
          resolvedExecutable: p.join(directory.path, 'app.exe'),
          environment: const {},
          pathProvider: _FakePathProvider(null),
        ),
      ),
      throwsStateError,
    );
  });
}
