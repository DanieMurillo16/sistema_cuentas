import 'package:sistema_cuentas/features/recurring/data/recurring_repository.dart';
import 'package:sistema_cuentas/features/recurring/models/finish_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_draft.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';

/// Repositorio de pagos recurrentes falso: cada operación se programa con una
/// función (o un `Completer`) y se cuentan las llamadas.
class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository({
    this.onList,
    this.onDetail,
    this.onCreate,
    this.onFinish,
    this.onDelete,
  });

  Future<List<RecurringPayment>> Function()? onList;
  Future<RecurringDetail> Function(int id)? onDetail;
  Future<RecurringPayment> Function(RecurringDraft draft)? onCreate;
  Future<void> Function(FinishDraft draft)? onFinish;
  Future<void> Function(int id)? onDelete;

  int listCalls = 0;
  int detailCalls = 0;
  int createCalls = 0;
  int finishCalls = 0;
  int deleteCalls = 0;
  final detailIds = <int>[];
  final created = <RecurringDraft>[];
  final finished = <FinishDraft>[];
  final deleted = <int>[];

  @override
  Future<List<RecurringPayment>> list() async {
    listCalls++;
    return onList == null ? const [] : onList!();
  }

  @override
  Future<RecurringDetail> detail(int id) {
    detailCalls++;
    detailIds.add(id);
    return onDetail!(id);
  }

  @override
  Future<RecurringPayment> create(RecurringDraft draft) {
    createCalls++;
    created.add(draft);
    return onCreate!(draft);
  }

  @override
  Future<void> delete(int id) async {
    deleteCalls++;
    deleted.add(id);
    await onDelete?.call(id);
  }

  @override
  Future<void> finish(FinishDraft draft) async {
    finishCalls++;
    finished.add(draft);
    await onFinish?.call(draft);
  }
}
