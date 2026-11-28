import 'dart:convert';

import '../core/url_utils.dart';

const configTransferPrefix = 'olivoscompanionconf://';
const _configFormat = 'olivos-companion-config';
const _configVersion = 1;

enum ConfigTransferFailure {
  invalidInstanceUrl,
  malformedInstanceUrl,
  notCompanionConfig,
  emptyContent,
  corruptedContent,
  invalidFormat,
  unsupportedVersion,
  noInstances,
  invalidInstanceFormat,
}

class ConfigTransferException implements Exception {
  const ConfigTransferException(this.failure, {this.detail});

  final ConfigTransferFailure failure;
  final String? detail;

  @override
  String toString() =>
      'ConfigTransferException(${failure.name}, detail: $detail)';
}

class InstanceConfigEntry {
  const InstanceConfigEntry({
    required this.name,
    required this.baseUrl,
    required this.autoLogin,
    this.password,
  });

  final String name;
  final String baseUrl;
  final bool autoLogin;
  final String? password;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'name': name,
      'baseUrl': baseUrl,
      'autoLogin': autoLogin,
    };
    if (password != null && password!.isNotEmpty) {
      json['password'] = password;
    }
    return json;
  }

  factory InstanceConfigEntry.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    final rawBaseUrl = json['baseUrl'];
    if (rawBaseUrl is! String) {
      throw const ConfigTransferException(
        ConfigTransferFailure.invalidInstanceUrl,
      );
    }

    final baseUrl = normalizeBaseUrl(rawBaseUrl);
    if (baseUrl == null) {
      throw ConfigTransferException(
        ConfigTransferFailure.malformedInstanceUrl,
        detail: rawBaseUrl,
      );
    }

    final name = rawName is String ? rawName.trim() : '';
    final rawPassword = json['password'];
    final rawAutoLogin = json['autoLogin'];
    return InstanceConfigEntry(
      name: name.isEmpty ? Uri.parse(baseUrl).host : name,
      baseUrl: baseUrl,
      autoLogin: rawAutoLogin is bool ? rawAutoLogin : true,
      password: rawPassword is String && rawPassword.isNotEmpty
          ? rawPassword
          : null,
    );
  }
}

class ConfigTransfer {
  static String encode(List<InstanceConfigEntry> entries) {
    final payload = <String, Object?>{
      'format': _configFormat,
      'version': _configVersion,
      'instances': entries.map((entry) => entry.toJson()).toList(),
    };
    final json = jsonEncode(payload);
    return '$configTransferPrefix${base64.encode(utf8.encode(json))}';
  }

  static List<InstanceConfigEntry> decode(String input) {
    final text = input.trim();
    if (!text.startsWith(configTransferPrefix)) {
      throw const ConfigTransferException(
        ConfigTransferFailure.notCompanionConfig,
      );
    }

    final encoded = text.substring(configTransferPrefix.length).trim();
    if (encoded.isEmpty) {
      throw const ConfigTransferException(ConfigTransferFailure.emptyContent);
    }

    dynamic decoded;
    try {
      final bytes = _decodeBase64(encoded);
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const ConfigTransferException(
        ConfigTransferFailure.corruptedContent,
      );
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != _configFormat) {
      throw const ConfigTransferException(ConfigTransferFailure.invalidFormat);
    }
    if (decoded['version'] != _configVersion) {
      throw const ConfigTransferException(
        ConfigTransferFailure.unsupportedVersion,
      );
    }

    final instances = decoded['instances'];
    if (instances is! List || instances.isEmpty) {
      throw const ConfigTransferException(ConfigTransferFailure.noInstances);
    }

    return instances.map<InstanceConfigEntry>((item) {
      if (item is! Map) {
        throw const ConfigTransferException(
          ConfigTransferFailure.invalidInstanceFormat,
        );
      }
      return InstanceConfigEntry.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  static List<int> _decodeBase64(String value) {
    try {
      return base64.decode(value);
    } on FormatException {
      return base64Url.decode(value);
    }
  }
}
