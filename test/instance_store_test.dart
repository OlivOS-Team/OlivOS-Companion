import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/data/instance_store.dart';
import 'package:olivos_companion/models/instance_profile.dart';

void main() {
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
  });
}
