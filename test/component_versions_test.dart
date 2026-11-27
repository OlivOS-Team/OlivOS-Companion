import 'package:flutter_test/flutter_test.dart';
import 'package:olivos_companion/features/about/component_versions.dart';

void main() {
  test('从 pubspec.lock 解析组件版本', () {
    final versions = parseComponentVersions('''
packages:
  alpha:
    dependency: "direct main"
    version: "1.2.3"
  beta:
    dependency: transitive
    version: "2.0.0"
  test_tool:
    dependency: "direct dev"
    version: "3.0.0"
''');

    expect(versions.map((component) => component.name), [
      'alpha',
      'beta',
      'test_tool',
    ]);
    expect(versions.first.version, '1.2.3');
    expect(versions[1].dependency, 'transitive');
    expect(versions.last.isDevDependency, isTrue);
  });

  testWidgets('打包的 pubspec.lock 可以读取', (tester) async {
    final versions = await loadComponentVersions();

    expect(versions, isNotEmpty);
    expect(versions.any((component) => component.name == 'yaml'), isTrue);
  });
}
