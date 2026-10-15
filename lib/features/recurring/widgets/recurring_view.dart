import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_list.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';

/// «Acuerdos»: la lista de pagos recurrentes con sus cuatro estados. El vacío
/// lo resuelve la lista (invita a crear el primero).
class RecurringView extends ConsumerWidget {
  const RecurringView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView(
      state: ref.watch(recurringListProvider),
      isEmpty: (_) => false,
      onRetry: () => ref.invalidate(recurringListProvider),
      builder: (_) => const RecurringList(),
    );
  }
}
