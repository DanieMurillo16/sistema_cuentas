import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_payment.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_delete_dialog.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_tile.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';

/// Un acuerdo de la lista: al tocarlo abre su detalle y, si la sesión puede
/// gestionar pagos recurrentes y sigue activo, se elimina deslizando.
class RecurringRow extends ConsumerWidget {
  const RecurringRow({super.key, required this.payment, required this.hidden});

  final RecurringPayment payment;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = ref.watch(
      hasPermissionProvider(Permissions.manageRecurring),
    );
    return RecurringTile(
      payment: payment,
      hidden: hidden,
      onTap: () => context.push(AppRoutes.recurringDetailFor(payment.id)),
      // Los finalizados ya lo están: no hay qué eliminar.
      onConfirmDelete: canDelete && payment.active
          ? () => confirmDeleteRecurring(
              context,
              recurringId: payment.id,
              name: RecurringRules.title(payment),
              isIncome: payment.isIncome,
            )
          : null,
    );
  }
}
