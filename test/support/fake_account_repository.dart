import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:sistema_cuentas/features/settings/data/account_repository.dart';

/// Repositorio de la cuenta falso: `onReset` se programa con una función (o un
/// `Completer` para controlar cuándo termina) y se cuentan las llamadas. Por
/// defecto el borrado sale bien.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.onReset});

  Future<void> Function()? onReset;

  int resetCalls = 0;

  @override
  Future<void> resetData() async {
    resetCalls++;
    await onReset?.call();
  }

  Override get asOverride => accountRepositoryProvider.overrideWithValue(this);
}
