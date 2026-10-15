import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_catalog_pickers.dart';
import 'package:sistema_cuentas/shared/widgets/app_retry_message.dart';
import 'package:sistema_cuentas/shared/widgets/catalog_pick_card.dart';

/// Elegir el medio de pago (obligatorio): una tarjeta que abre su selector
/// desde abajo. Resuelve cargando, error y vacío: sin medios no se puede
/// registrar nada, y lo dice.
class PaymentMethodField extends ConsumerWidget {
  const PaymentMethodField({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.label = 'Medio de pago',
  });

  final PaymentMethod? value;
  final ValueChanged<PaymentMethod?> onChanged;
  final FormFieldValidator<PaymentMethod>? validator;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(activePaymentMethodsProvider);
    if (methods.hasError && !methods.hasValue) {
      return AppRetryMessage(
        text: userErrorMessage(methods.error),
        onRetry: () => ref.invalidate(paymentMethodsProvider),
      );
    }
    if (!methods.hasValue) return const LinearProgressIndicator();
    if (methods.requireValue.isEmpty) {
      return AppRetryMessage(
        text: 'Aún no tienes medios de pago activos.',
        onRetry: () => ref.invalidate(paymentMethodsProvider),
      );
    }
    return CatalogPickCard(
      label: label,
      placeholderIcon: Icons.account_balance_wallet_outlined,
      selected: value == null ? null : methodOption(value!),
      validator: () => validator?.call(value),
      onTap: () async {
        final picked = await pickMethod(
          context,
          ref,
          items: methods.requireValue,
          selected: value,
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
