import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_paths.dart';
import '../models/instance_profile.dart';

class InstanceStore {
  InstanceStore({FlutterSecureStorage? secureStorage, this.dataDirectory})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _profilesKey = 'instances.v1';
  static const _profilesFileName = 'instances.json';
  static const _passwordPrefix = 'password.';

  final FlutterSecureStorage _secureStorage;
  final Directory? dataDirectory;

  Future<File> _profilesFile() async {
    final directory = dataDirectory ?? await AppPaths.dataDirectory();
    return File(p.join(directory.path, _profilesFileName));
  }

  Future<List<InstanceProfile>> loadProfiles() async {
    final file = await _profilesFile();
    if (await file.exists()) {
      try {
        return _decode(await file.readAsString());
      } catch (_) {
        // Fall through to the legacy store so a damaged file does not hide
        // profiles from an older installation.
      }
    }

    if (AppPaths.isPortable) return [];
    return _migrateLegacyProfiles(file);
  }

  Future<void> saveProfiles(List<InstanceProfile> profiles) async {
    final file = await _profilesFile();
    await _writeProfiles(file, profiles);
  }

  Future<List<InstanceProfile>> _migrateLegacyProfiles(File file) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_profilesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final profiles = _decode(raw);
      if (profiles.isNotEmpty) {
        await _writeProfiles(file, profiles);
      }
      return profiles;
    } catch (_) {
      return [];
    }
  }

  List<InstanceProfile> _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map(
          (item) => InstanceProfile.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> _writeProfiles(File file, List<InstanceProfile> profiles) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
      flush: true,
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
