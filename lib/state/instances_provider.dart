import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/config_transfer.dart';
import '../data/instance_store.dart';
import '../models/instance_profile.dart';

final instanceStoreProvider = Provider<InstanceStore>((ref) => InstanceStore());

final instancesProvider =
    AsyncNotifierProvider<InstancesNotifier, List<InstanceProfile>>(
      InstancesNotifier.new,
    );

class InstancesNotifier extends AsyncNotifier<List<InstanceProfile>> {
  @override
  Future<List<InstanceProfile>> build() {
    return ref.read(instanceStoreProvider).loadProfiles();
  }

  Future<void> addProfile({
    required String name,
    required String baseUrl,
    required bool autoLogin,
    String? password,
  }) async {
    final store = ref.read(instanceStoreProvider);
    final profile = InstanceProfile(
      id: const Uuid().v4(),
      name: name,
      baseUrl: baseUrl,
      autoLogin: autoLogin,
    );
    final current = state.value ?? await store.loadProfiles();
    final updated = [...current, profile];
    await store.saveProfiles(updated);
    if (autoLogin && password != null && password.isNotEmpty) {
      await store.savePassword(profile.id, password);
    }
    state = AsyncData(updated);
  }

  Future<void> updateProfile({
    required String id,
    required String name,
    required String baseUrl,
    required bool autoLogin,
    String? password,
  }) async {
    final store = ref.read(instanceStoreProvider);
    final current = state.value ?? await store.loadProfiles();
    final index = current.indexWhere((profile) => profile.id == id);
    if (index < 0) return;

    final existing = current[index];
    final baseUrlChanged = existing.baseUrl != baseUrl;
    final updated = [...current];
    updated[index] = InstanceProfile(
      id: existing.id,
      name: name,
      baseUrl: baseUrl,
      autoLogin: autoLogin,
      // Cached version data belongs to the previous server.
      version: baseUrlChanged ? null : existing.version,
      versionSlogan: baseUrlChanged ? null : existing.versionSlogan,
    );

    await store.saveProfiles(updated);
    if (!autoLogin) {
      await store.deletePassword(id);
    } else if (password != null && password.isNotEmpty) {
      await store.savePassword(id, password);
    }
    state = AsyncData(updated);
  }

  Future<int> importConfig(List<InstanceConfigEntry> entries) async {
    final store = ref.read(instanceStoreProvider);
    final current = state.value ?? await store.loadProfiles();
    final updated = [...current];

    for (final entry in entries) {
      final index = updated.indexWhere(
        (profile) => profile.baseUrl == entry.baseUrl,
      );
      if (index >= 0) {
        final existing = updated[index];
        updated[index] = existing.copyWith(
          name: entry.name,
          autoLogin: entry.autoLogin,
        );
        if (!entry.autoLogin) {
          await store.deletePassword(existing.id);
        } else if (entry.password != null) {
          await store.savePassword(existing.id, entry.password!);
        }
        continue;
      }

      final profile = InstanceProfile(
        id: const Uuid().v4(),
        name: entry.name,
        baseUrl: entry.baseUrl,
        autoLogin: entry.autoLogin,
      );
      updated.add(profile);
      if (entry.autoLogin && entry.password != null) {
        await store.savePassword(profile.id, entry.password!);
      }
    }

    await store.saveProfiles(updated);
    state = AsyncData(updated);
    return entries.length;
  }

  Future<void> removeProfile(String id) {
    return removeProfiles([id]);
  }

  Future<void> removeProfiles(Iterable<String> ids) async {
    final removedIds = ids.toSet();
    if (removedIds.isEmpty) return;

    final store = ref.read(instanceStoreProvider);
    final current = state.value ?? await store.loadProfiles();
    final removed = current
        .where((profile) => removedIds.contains(profile.id))
        .map((profile) => profile.id)
        .toList();
    if (removed.isEmpty) return;

    final updated = current
        .where((profile) => !removedIds.contains(profile.id))
        .toList();
    await store.saveProfiles(updated);
    for (final id in removed) {
      await store.deletePassword(id);
    }
    state = AsyncData(updated);
  }
}
