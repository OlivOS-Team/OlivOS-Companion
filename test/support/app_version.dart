import 'dart:io';

import 'package:yaml/yaml.dart';

/// Reads the application version from the single source of truth: pubspec.yaml.
class AppVersionFixture {
  const AppVersionFixture._({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get fullVersion =>
      buildNumber.isEmpty ? version : '$version+$buildNumber';

  static AppVersionFixture load({String pubspecPath = 'pubspec.yaml'}) {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      throw StateError('Cannot find $pubspecPath');
    }
    final document = loadYaml(file.readAsStringSync());
    if (document is! YamlMap) {
      throw StateError('$pubspecPath is not a YAML map');
    }
    final rawValue = document['version'];
    if (rawValue is! String || rawValue.trim().isEmpty) {
      throw StateError('$pubspecPath has no version');
    }

    final value = rawValue.trim();
    final separator = value.indexOf('+');
    final version = separator == -1 ? value : value.substring(0, separator);
    final buildNumber = separator == -1 ? '' : value.substring(separator + 1);
    if (version.isEmpty) {
      throw StateError('$pubspecPath has an invalid version');
    }
    return AppVersionFixture._(version: version, buildNumber: buildNumber);
  }
}
