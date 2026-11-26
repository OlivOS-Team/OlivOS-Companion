import 'dart:convert';

import '../core/url_utils.dart';

const configTransferPrefix = 'olivoscompanionconf://';
const _configFormat = 'olivos-companion-config';
const _configVersion = 1;

class ConfigTransferException implements Exception {
  const ConfigTransferException(this.message);

  final String message;

  @override
  String toString() => message;
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
      throw const ConfigTransferException('配置中的实例地址无效');
    }

    final baseUrl = normalizeBaseUrl(rawBaseUrl);
    if (baseUrl == null) {
      throw ConfigTransferException('实例地址无效：$rawBaseUrl');
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
      throw const ConfigTransferException('不是 OlivOS Companion 配置');
    }

    final encoded = text.substring(configTransferPrefix.length).trim();
    if (encoded.isEmpty) {
      throw const ConfigTransferException('配置内容为空');
    }

    dynamic decoded;
    try {
      final bytes = _decodeBase64(encoded);
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const ConfigTransferException('配置内容损坏或编码不正确');
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != _configFormat) {
      throw const ConfigTransferException('配置格式不正确');
    }
    if (decoded['version'] != _configVersion) {
      throw const ConfigTransferException('配置版本不受支持');
    }

    final instances = decoded['instances'];
    if (instances is! List || instances.isEmpty) {
      throw const ConfigTransferException('配置中没有实例');
    }

    return instances.map<InstanceConfigEntry>((item) {
      if (item is! Map) {
        throw const ConfigTransferException('配置中的实例格式不正确');
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
