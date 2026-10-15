import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/dues/widgets/dues_list.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';

/// «Este mes»: quién pagó y quién no, con los cuatro estados. Al refrescar o
/// pagar conserva lo que se ve y solo asoma una barra fina arriba.
class DuesView extends ConsumerWidget {
  const DuesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAsyncView(
      state: ref.watch(duesProvider),
      isEmpty: (month) => month.dues.isEmpty,
      emptyIcon: Icons.event_available_outlined,
      emptyTitle: 'Sin vencimientos este mes',
      emptyMessage:
          'Cuando tengas pagos recurrentes, aquí verás quién pagó y quién no.',
      onRetry: () => ref.invalidate(duesProvider),
      builder: (month) => DuesList(month: month),
    );
  }
}
