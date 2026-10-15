import 'package:sistema_cuentas/features/dues/data/dues_repository.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';

/// Repositorio de vencimientos falso. Por defecto devuelve un mes sin nada.
class FakeDuesRepository implements DuesRepository {
  FakeDuesRepository([this.onMonth]);

  Future<DuesMonth> Function(DateTime month)? onMonth;

  int calls = 0;
  final months = <DateTime>[];

  @override
  Future<DuesMonth> month(DateTime month) async {
    calls++;
    months.add(month);
    return onMonth == null
        ? const DuesMonth(dues: [], totals: [])
        : onMonth!(month);
  }
}
