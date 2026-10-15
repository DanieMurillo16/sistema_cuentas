import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/catalogs/widgets/payment_method_dialog.dart';
import 'package:sistema_cuentas/shared/providers/permission_provider.dart';
import 'package:sistema_cuentas/shared/widgets/manage_list_scaffold.dart';
import 'package:sistema_cuentas/shared/widgets/manage_tile.dart';

/// Ajustes → Medios de pago: ver, crear y editar.
/// pantalla → paymentMethodsProvider → CatalogsRepository → catalogos/medios.php
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = ref.watch(
      hasPermissionProvider(Permissions.manageCatalogs),
    );
    return ManageListScaffold(
      title: 'Medios de pago',
      state: ref.watch(paymentMethodsProvider),
      onRetry: () => ref.invalidate(paymentMethodsProvider),
      emptyTitle: 'Sin medios de pago',
      emptyMessage:
          'Crea Nequi, Bancolombia, efectivo… para registrar tus pagos.',
      createTooltip: 'Nuevo medio de pago',
      onCreate: canManage ? () => showPaymentMethodDialog(context) : null,
      itemBuilder: (context, method) => ManageTile(
        key: ValueKey('method-${method.id}'),
        title: method.name,
        icon: Icons.account_balance_wallet_outlined,
        inactive: !method.active,
        onTap: canManage
            ? () => showPaymentMethodDialog(context, method: method)
            : null,
      ),
    );
  }
}
