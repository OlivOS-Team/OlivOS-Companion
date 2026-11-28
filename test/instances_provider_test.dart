import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/models/instance_profile.dart';
import 'package:olivos_companion/state/instances_provider.dart';

import 'support/memory_instance_store.dart';
import 'support/test_fixtures.dart';

ProviderContainer _createContainer(MemoryInstanceStore store) {
  final container = ProviderContainer(
    overrides: [instanceStoreProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('addProfile 保存实例和自动登录密码', () async {
    final store = MemoryInstanceStore();
    final container = _createContainer(store);
    await container.read(instancesProvider.future);

    await container
        .read(instancesProvider.notifier)
        .addProfile(
          name: '主实例',
          baseUrl: testBaseUrl,
          autoLogin: true,
          password: testPassword,
        );

    final profiles = container.read(instancesProvider).value!;
    expect(profiles, hasLength(1));
    expect(profiles.single.name, '主实例');
    expect(store.profiles, hasLength(1));
    expect(store.passwords[profiles.single.id], testPassword);
    expect(store.saveCount, 1);
  });

  test('updateProfile 清理旧版本缓存并处理密码', () async {
    final store = MemoryInstanceStore(
      initialProfiles: const [
        InstanceProfile(
          id: 'dev',
          name: '旧名称',
          baseUrl: testBaseUrl,
          version: testWebUiVersion,
          versionSlogan: testWebUiSlogan,
        ),
      ],
      initialPasswords: const {'dev': 'old-password'},
    );
    final container = _createContainer(store);
    await container.read(instancesProvider.future);
    final notifier = container.read(instancesProvider.notifier);

    await notifier.updateProfile(
      id: 'dev',
      name: '新名称',
      baseUrl: testBaseUrl,
      autoLogin: true,
    );
    var profile = container.read(instancesProvider).value!.single;
    expect(profile.name, '新名称');
    expect(profile.version, testWebUiVersion);
    expect(store.passwords['dev'], 'old-password');

    await notifier.updateProfile(
      id: 'dev',
      name: '新名称',
      baseUrl: testBaseUrl2,
      autoLogin: true,
      password: 'new-password',
    );
    profile = container.read(instancesProvider).value!.single;
    expect(profile.version, isNull);
    expect(profile.versionSlogan, isNull);
    expect(store.passwords['dev'], 'new-password');

    await notifier.updateProfile(
      id: 'dev',
      name: '新名称',
      baseUrl: testBaseUrl2,
      autoLogin: false,
    );
    expect(store.passwords.containsKey('dev'), isFalse);
  });

  test('importConfig 更新同地址实例并新增不同地址实例', () async {
    final store = MemoryInstanceStore(
      initialProfiles: const [
        InstanceProfile(id: 'existing', name: '旧名称', baseUrl: testBaseUrl),
      ],
      initialPasswords: const {'existing': 'old-password'},
    );
    final container = _createContainer(store);
    await container.read(instancesProvider.future);

    final count = await container.read(instancesProvider.notifier).importConfig(
      [
        const InstanceConfigEntry(
          name: '更新后',
          baseUrl: testBaseUrl,
          autoLogin: false,
        ),
        const InstanceConfigEntry(
          name: '新增',
          baseUrl: testBaseUrl2,
          autoLogin: true,
          password: 'new-password',
        ),
      ],
    );

    final profiles = container.read(instancesProvider).value!;
    expect(count, 2);
    expect(profiles, hasLength(2));
    expect(
      profiles.firstWhere((profile) => profile.id == 'existing').name,
      '更新后',
    );
    expect(store.passwords.containsKey('existing'), isFalse);
    final added = profiles.firstWhere((profile) => profile.name == '新增');
    expect(store.passwords[added.id], 'new-password');
  });

  test('更新不存在的实例会被忽略', () async {
    final store = MemoryInstanceStore();
    final container = _createContainer(store);
    await container.read(instancesProvider.future);

    await container
        .read(instancesProvider.notifier)
        .updateProfile(
          id: 'missing',
          name: '不存在',
          baseUrl: testBaseUrl,
          autoLogin: true,
        );

    expect(container.read(instancesProvider).value, isEmpty);
    expect(store.saveCount, 0);
  });

  test('删除空选择或不存在的实例不会写入', () async {
    final store = MemoryInstanceStore(
      initialProfiles: const [
        InstanceProfile(id: 'a', name: 'a', baseUrl: testBaseUrl),
      ],
    );
    final container = _createContainer(store);
    await container.read(instancesProvider.future);

    final notifier = container.read(instancesProvider.notifier);
    await notifier.removeProfiles(const []);
    await notifier.removeProfiles(const ['missing']);

    expect(container.read(instancesProvider).value, hasLength(1));
    expect(store.saveCount, 0);
  });

  test('removeProfiles 只删除选中实例及其密码', () async {
    final store = MemoryInstanceStore(
      initialProfiles: const [
        InstanceProfile(id: 'a', name: 'a', baseUrl: testBaseUrl),
        InstanceProfile(id: 'b', name: 'b', baseUrl: testBaseUrl2),
        InstanceProfile(id: 'c', name: 'c', baseUrl: testBaseUrl3),
      ],
      initialPasswords: const {
        'a': 'a-password',
        'b': 'b-password',
        'c': 'c-password',
      },
    );
    final container = _createContainer(store);
    await container.read(instancesProvider.future);

    await container.read(instancesProvider.notifier).removeProfiles(['a', 'c']);

    final profiles = container.read(instancesProvider).value!;
    expect(profiles.map((profile) => profile.id), ['b']);
    expect(store.passwords, {'b': 'b-password'});
    expect(store.saveCount, 1);
  });
}
