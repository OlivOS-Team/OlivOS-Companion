import '../core/url_utils.dart';

class InstanceProfile {
  const InstanceProfile({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.autoLogin = true,
  });

  final String id;
  final String name;
  final String baseUrl;
  final bool autoLogin;

  String get origin => originOf(baseUrl);

  InstanceProfile copyWith({String? name, String? baseUrl, bool? autoLogin}) {
    return InstanceProfile(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      autoLogin: autoLogin ?? this.autoLogin,
    );
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'name': name, 'baseUrl': baseUrl, 'autoLogin': autoLogin};
  }

  factory InstanceProfile.fromJson(Map<String, dynamic> json) {
    return InstanceProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      autoLogin: json['autoLogin'] as bool? ?? true,
    );
  }
}
