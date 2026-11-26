import '../core/url_utils.dart';

class InstanceProfile {
  const InstanceProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.autoLogin = true,
    this.version,
    this.versionSlogan,
  });

  final String id;
  final String name;
  final String baseUrl;
  final bool autoLogin;

  /// Last version reported by the instance's `/api/health`.
  final String? version;
  final String? versionSlogan;

  String get origin => originOf(baseUrl);

  String get displayName {
    final currentVersion = version?.trim();
    if (currentVersion == null || currentVersion.isEmpty) return name;

    final currentSlogan = versionSlogan?.trim();
    if (currentSlogan == null || currentSlogan.isEmpty) {
      return '$name · $currentVersion';
    }
    return '$name · $currentVersion - $currentSlogan';
  }

  InstanceProfile copyWith({
    String? name,
    String? baseUrl,
    bool? autoLogin,
    String? version,
    String? versionSlogan,
  }) {
    return InstanceProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      autoLogin: autoLogin ?? this.autoLogin,
      version: version ?? this.version,
      versionSlogan: versionSlogan ?? this.versionSlogan,
    );
  }

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'name': name,
      'baseUrl': baseUrl,
      'autoLogin': autoLogin,
    };
    if (version != null) json['version'] = version;
    if (versionSlogan != null) json['versionSlogan'] = versionSlogan;
    return json;
  }

  factory InstanceProfile.fromJson(Map<String, dynamic> json) {
    return InstanceProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      autoLogin: json['autoLogin'] as bool? ?? true,
      version: json['version'] as String?,
      versionSlogan: json['versionSlogan'] as String?,
    );
  }
}
