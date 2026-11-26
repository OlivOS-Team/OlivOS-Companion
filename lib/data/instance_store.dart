import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/instance_profile.dart';

class InstanceStore {
  InstanceStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _profilesKey = 'instances.v1';
  static const _passwordPrefix = 'password.';

  final FlutterSecureStorage _secureStorage;

  Future<List<InstanceProfile>> loadProfiles() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_profilesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => InstanceProfile.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProfiles(List<InstanceProfile> profiles) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  Future<void> saveVersion({
    required String id,
    required String version,
    String? versionSlogan,
  }) async {
    final profiles = await loadProfiles();
    var changed = false;
    final updated = profiles.map((profile) {
      if (profile.id != id ||
          (profile.version == version &&
              profile.versionSlogan == versionSlogan)) {
        return profile;
      }
      changed = true;
      return profile.copyWith(version: version, versionSlogan: versionSlogan);
    }).toList();
    if (changed) await saveProfiles(updated);
  }

  Future<void> savePassword(String id, String password) async {
    if (password.isEmpty) return;
    await _secureStorage.write(key: '$_passwordPrefix$id', value: password);
  }

  Future<String?> readPassword(String id) {
    return _secureStorage.read(key: '$_passwordPrefix$id');
  }

  Future<void> deletePassword(String id) async {
    await _secureStorage.delete(key: '$_passwordPrefix$id');
  }
}
