import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/models/instance_profile.dart';

import 'support/test_fixtures.dart';

void main() {
  test('displayName 拼出版本号和版本名', () {
    const profile = InstanceProfile(
      id: testInstanceName,
      name: testInstanceName,
      baseUrl: testBaseUrl,
      version: testWebUiVersion,
      versionSlogan: testWebUiSlogan,
    );

    expect(
      profile.displayName,
      '$testInstanceName · $testWebUiVersion - $testWebUiSlogan',
    );
  });

  test('没有缓存版本时只显示名称', () {
    const profile = InstanceProfile(
      id: testInstanceName,
      name: testInstanceName,
      baseUrl: testBaseUrl,
    );

    expect(profile.displayName, testInstanceName);
  });

  test('JSON 往返保留版本缓存', () {
    const profile = InstanceProfile(
      id: testInstanceName,
      name: testInstanceName,
      baseUrl: testBaseUrl,
      version: testWebUiVersion,
      versionSlogan: testWebUiSlogan,
    );

    final restored = InstanceProfile.fromJson(
      Map<String, dynamic>.from(profile.toJson()),
    );

    expect(restored.version, testWebUiVersion);
    expect(restored.versionSlogan, testWebUiSlogan);
  });
}
