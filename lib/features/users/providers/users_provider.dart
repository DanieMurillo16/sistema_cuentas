import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/users/data/users_repository.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Las personas con acceso (solo la ve el administrador). Un solo lugar:
/// crear y activar/desactivar actualizan esta lista.
final usersProvider = AsyncNotifierProvider<UsersNotifier, List<ManagedUser>>(
  UsersNotifier.new,
);

class UsersNotifier extends AsyncNotifier<List<ManagedUser>> {
  @override
  Future<List<ManagedUser>> build() {
    ref.watch(sessionUserIdProvider);
    return ref.read(usersRepositoryProvider).list();
  }

  void upsert(ManagedUser user) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((u) => u.id == user.id);
    state = AsyncData([
      for (final u in current)
        if (u.id == user.id) user else u,
      if (!exists) user,
    ]);
  }
}

/// Escritura: dar de alta a una persona.
final saveUserProvider =
    AsyncNotifierProvider.autoDispose<SaveUserNotifier, void>(
      SaveUserNotifier.new,
    );

class SaveUserNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> save(UserDraft draft) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final user = await ref.read(usersRepositoryProvider).create(draft);
        ref.read(usersProvider.notifier).upsert(user);
      });
    } finally {
      keepAlive.close();
    }
  }
}

/// Escritura: activar o desactivar a alguien.
final setUserActiveProvider =
    AsyncNotifierProvider.autoDispose<SetUserActiveNotifier, void>(
      SetUserActiveNotifier.new,
    );

class SetUserActiveNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> setActive(int id, {required bool active}) async {
    if (state.isLoading) return;
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() async {
        final user = await ref
            .read(usersRepositoryProvider)
            .setActive(id, active: active);
        ref.read(usersProvider.notifier).upsert(user);
      });
    } finally {
      keepAlive.close();
    }
  }
}
