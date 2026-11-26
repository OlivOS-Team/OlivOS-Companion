import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/config_transfer.dart';
import 'package:olivos_companion/data/instance_store.dart';
import 'package:olivos_companion/models/instance_profile.dart';
import 'package:olivos_companion/state/instances_provider.dart';

void main() {
  test('导入配置会新增实例并更新相同地址', () async {
    final directory = await Directory.systemTemp.createTemp(
      'olivos-config-import-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final store = InstanceStore(dataDirectory: directory);
    await store.saveProfiles([
      const InstanceProfile(
        id: 'existing',
        name: 'old',
        baseUrl: 'http://127.0.0.1:20480',
      ),
    ]);

    final container = ProviderContainer(
      overrides: [instanceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    await container.read(instancesProvider.future);

    final count = await container.read(instancesProvider.notifier).importConfig(
      [
        const InstanceConfigEntry(
          name: 'updated',
          baseUrl: 'http://127.0.0.1:20480',
          autoLogin: true,
        ),
        const InstanceConfigEntry(
          name: 'new',
          baseUrl: 'http://127.0.0.1:20481',
          autoLogin: false,
        ),
      ],
    );

    expect(count, 2);
    final profiles = await store.loadProfiles();
    expect(profiles, hasLength(2));
    expect(
      profiles.firstWhere((profile) => profile.id == 'existing').name,
      'updated',
    );
    expect(
      profiles.any(
        (profile) =>
            profile.name == 'new' &&
            profile.baseUrl == 'http://127.0.0.1:20481',
      ),
      isTrue,
    );
  });
}
