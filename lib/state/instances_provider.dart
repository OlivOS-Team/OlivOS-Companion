import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

  Future<void> removeProfile(String id) async {
    final store = ref.read(instanceStoreProvider);
    final current = state.value ?? await store.loadProfiles();
    final updated = current.where((profile) => profile.id != id).toList();
    await store.saveProfiles(updated);
    await store.deletePassword(id);
    state = AsyncData(updated);
  }
}
