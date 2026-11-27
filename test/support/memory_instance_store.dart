import 'dart:io';

import 'package:olivos_companion/data/instance_store.dart';
import 'package:olivos_companion/models/instance_profile.dart';

class MemoryInstanceStore extends InstanceStore {
  MemoryInstanceStore({
    List<InstanceProfile> initialProfiles = const [],
    Map<String, String> initialPasswords = const {},
  }) : _profiles = [...initialProfiles],
       _passwords = {...initialPasswords},
       super(dataDirectory: Directory.systemTemp);

  List<InstanceProfile> _profiles;
  final Map<String, String> _passwords;
  int saveCount = 0;

  List<InstanceProfile> get profiles => List.unmodifiable(_profiles);
  Map<String, String> get passwords => Map.unmodifiable(_passwords);

  @override
  Future<List<InstanceProfile>> loadProfiles() async => [..._profiles];

  @override
  Future<void> saveProfiles(List<InstanceProfile> profiles) async {
    _profiles = [...profiles];
    saveCount++;
  }

  @override
  Future<String?> readPassword(String id) async => _passwords[id];

  @override
  Future<void> savePassword(String id, String password) async {
    if (password.isEmpty) return;
    _passwords[id] = password;
  }

  @override
  Future<void> deletePassword(String id) async {
    _passwords.remove(id);
  }
}
