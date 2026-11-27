import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// A locked dependency with the version that is actually built into the app.
class ComponentVersion {
  const ComponentVersion({
    required this.name,
    required this.version,
    required this.dependency,
  });

  final String name;
  final String version;

  /// Pub's dependency scope, for example `direct main`, `transitive`, or
  /// `direct dev`.
  final String dependency;

  bool get isDevDependency => dependency == 'direct dev';
}

/// Reads versions from the lockfile bundled as an asset.
Future<List<ComponentVersion>> loadComponentVersions() async {
  return parseComponentVersions(await rootBundle.loadString('pubspec.lock'));
}

List<ComponentVersion> parseComponentVersions(String lockFile) {
  final document = loadYaml(lockFile);
  if (document is! Map) return const [];
  final packages = document['packages'];
  if (packages is! Map) return const [];

  final components = <ComponentVersion>[];
  for (final entry in packages.entries) {
    final data = entry.value;
    if (data is! Map) continue;
    final version = data['version']?.toString().trim();
    if (version == null || version.isEmpty) continue;
    components.add(
      ComponentVersion(
        name: entry.key.toString(),
        version: version,
        dependency: data['dependency']?.toString() ?? '',
      ),
    );
  }
  components.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return components;
}
