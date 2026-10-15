import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/dues/models/due.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_tile.dart';
import 'package:sistema_cuentas/features/dues/widgets/pay_due_dialog.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_delete_dialog.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';

/// Un vencimiento de «Este mes» con sus acciones: pagarlo o cobrarlo, y —si la
/// sesión puede gestionar pagos recurrentes— eliminar su acuerdo deslizando.
class DueRow extends ConsumerWidget {
  const DueRow({super.key, required this.due, required this.hidden});

  final Due due;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = ref.watch(
      hasPermissionProvider(Permissions.manageRecurring),
    );
    return DueTile(
      due: due,
      hidden: hidden,
      onPay: () => showPayDueDialog(context, due),
      onConfirmDelete: canDelete
          ? () => confirmDeleteRecurring(
              context,
              recurringId: due.recurringId,
              name: DuesRules.tileTitle(due),
              isIncome: due.isIncome,
            )
          : null,
    );
  }
}
