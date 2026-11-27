import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/core/app_paths.dart';
import 'package:olivos_companion/data/instance_store.dart';
import 'package:olivos_companion/models/instance_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  setUp(AppPaths.resetForTesting);
  test('实例数据写入指定目录并保留版本缓存', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-instance-store-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final store = InstanceStore(dataDirectory: directory);
    await store.saveProfiles([
      const InstanceProfile(
        id: 'dev',
        name: 'dev',
        baseUrl: 'http://127.0.0.1:20480',
        version: '1.0.5(300)',
        versionSlogan: '妖刀村正',
      ),
    ]);

    expect(File('${directory.path}/instances.json').existsSync(), isTrue);
    final profiles = await store.loadProfiles();
    expect(profiles, hasLength(1));
    expect(profiles.single.displayName, 'dev · 1.0.5(300) - 妖刀村正');
  });

  test('saveVersion 只更新指定实例', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-instance-store-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final store = InstanceStore(dataDirectory: directory);
    await store.saveProfiles([
      const InstanceProfile(
        id: 'a',
        name: 'a',
        baseUrl: 'http://127.0.0.1:20480',
      ),
      const InstanceProfile(
        id: 'b',
        name: 'b',
        baseUrl: 'http://127.0.0.1:20481',
      ),
    ]);

    await store.saveVersion(
      id: 'a',
      version: '1.0.5(300)',
      versionSlogan: '妖刀村正',
    );

    final profiles = await store.loadProfiles();
    expect(profiles[0].version, '1.0.5(300)');
    expect(profiles[1].version, isNull);

    await store.saveVersion(
      id: 'a',
      version: '1.0.5(300)',
      versionSlogan: '妖刀村正',
    );
    expect((await store.loadProfiles())[0].version, '1.0.5(300)');
  });

  test('损坏的实例文件会按空数据处理', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-instance-store-',
    );
    addTearDown(() => directory.delete(recursive: true));
    await File('${directory.path}/instances.json').writeAsString('{bad json');
    SharedPreferences.setMockInitialValues({});

    final store = InstanceStore(dataDirectory: directory);
    expect(await store.loadProfiles(), isEmpty);
  });

  test('旧版 SharedPreferences 数据会迁移到 instances.json', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-instance-store-',
    );
    addTearDown(() => directory.delete(recursive: true));
    SharedPreferences.setMockInitialValues({
      'instances.v1': jsonEncode([
        {
          'id': 'legacy',
          'name': '旧实例',
          'baseUrl': 'http://127.0.0.1:20480',
          'autoLogin': true,
        },
      ]),
    });

    final store = InstanceStore(dataDirectory: directory);
    final profiles = await store.loadProfiles();
    expect(profiles, hasLength(1));
    expect(profiles.single.id, 'legacy');
    expect(File('${directory.path}/instances.json').existsSync(), isTrue);
  });

  test('无效的旧版数据不会被导入', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-instance-store-',
    );
    addTearDown(() => directory.delete(recursive: true));
    SharedPreferences.setMockInitialValues({'instances.v1': '{invalid'});

    final store = InstanceStore(dataDirectory: directory);
    expect(await store.loadProfiles(), isEmpty);
  });

  test('密码可写入、读取和删除，空密码忽略', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-instance-store-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final secureStorage = _MemorySecureStorage();
    final store = InstanceStore(
      dataDirectory: directory,
      secureStorage: secureStorage,
    );

    await store.savePassword('a', 'secret');
    expect(await store.readPassword('a'), 'secret');
    await store.savePassword('empty', '');
    expect(await store.readPassword('empty'), isNull);
    await store.deletePassword('a');
    expect(await store.readPassword('a'), isNull);
  });
}
