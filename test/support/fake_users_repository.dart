import 'package:sistema_cuentas/features/users/data/users_repository.dart';
import 'package:sistema_cuentas/features/users/models/managed_user.dart';
import 'package:sistema_cuentas/features/users/models/user_draft.dart';

/// Repositorio de usuarios falso: se programa con funciones (o `Completer`) y
/// se cuentan las llamadas. Por defecto la lista está vacía.
class FakeUsersRepository implements UsersRepository {
  FakeUsersRepository({this.onList, this.onCreate, this.onSetActive});

  Future<List<ManagedUser>> Function()? onList;
  Future<ManagedUser> Function(UserDraft draft)? onCreate;
  Future<ManagedUser> Function(int id, bool active)? onSetActive;

  int listCalls = 0;
  int createCalls = 0;
  int setActiveCalls = 0;
  final created = <UserDraft>[];
  final activeChanges = <(int id, bool active)>[];

  @override
  Future<List<ManagedUser>> list() async {
    listCalls++;
    return onList == null ? const [] : onList!();
  }

  @override
  Future<ManagedUser> create(UserDraft draft) {
    createCalls++;
    created.add(draft);
    return onCreate!(draft);
  }

  @override
  Future<ManagedUser> setActive(int id, {required bool active}) {
    setActiveCalls++;
    activeChanges.add((id, active));
    return onSetActive!(id, active);
  }
}
