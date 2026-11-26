import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/models/instance_profile.dart';

void main() {
  test('displayName 拼出版本号和版本名', () {
    const profile = InstanceProfile(
      id: 'dev',
      name: 'dev',
      baseUrl: 'http://127.0.0.1:20480',
      version: '1.0.5(300)',
      versionSlogan: '妖刀村正',
    );

    expect(profile.displayName, 'dev · 1.0.5(300) - 妖刀村正');
  });

  test('没有缓存版本时只显示名称', () {
    const profile = InstanceProfile(
      id: 'dev',
      name: 'dev',
      baseUrl: 'http://127.0.0.1:20480',
    );

    expect(profile.displayName, 'dev');
  });

  test('JSON 往返保留版本缓存', () {
    const profile = InstanceProfile(
      id: 'dev',
      name: 'dev',
      baseUrl: 'http://127.0.0.1:20480',
      version: '1.0.5(300)',
      versionSlogan: '妖刀村正',
    );

    final restored = InstanceProfile.fromJson(
      Map<String, dynamic>.from(profile.toJson()),
    );

    expect(restored.version, '1.0.5(300)');
    expect(restored.versionSlogan, '妖刀村正');
  });
}
