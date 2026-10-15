import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_retry_message.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_catalog_pair.dart';

/// Categoría y medio de pago (obligatorios): dos tarjetas lado a lado que abren su selector. Si los
/// catálogos no cargan o están vacíos, lo dice y permite reintentar.
class MovementCatalogFields extends ConsumerWidget {
  const MovementCatalogFields({
    super.key,
    required this.type,
    required this.category,
    required this.method,
    required this.onCategoryChanged,
    required this.onMethodChanged,
  });

  final MovementType type;
  final Category? category;
  final PaymentMethod? method;
  final ValueChanged<Category?> onCategoryChanged;
  final ValueChanged<PaymentMethod?> onMethodChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesForTypeProvider(type));
    final methods = ref.watch(activePaymentMethodsProvider);
    final error =
        (categories.hasValue ? null : categories.error) ??
        (methods.hasValue ? null : methods.error);
    if (error != null) {
      return AppRetryMessage(
        text: userErrorMessage(error),
        onRetry: () {
          ref.invalidate(categoriesProvider);
          ref.invalidate(paymentMethodsProvider);
        },
      );
    }
    if (!categories.hasValue || !methods.hasValue) {
      return const LinearProgressIndicator();
    }
    if (categories.requireValue.isEmpty) {
      return AppRetryMessage(
        text:
            'Aún no tienes categorías de '
            '${type.isIncome ? 'ingresos' : 'gastos'} activas.',
        onRetry: () => ref.invalidate(categoriesProvider),
      );
    }
    if (methods.requireValue.isEmpty) {
      return AppRetryMessage(
        text: 'Aún no tienes medios de pago activos.',
        onRetry: () => ref.invalidate(paymentMethodsProvider),
      );
    }
    return MovementCatalogPair(
      type: type,
      category: category,
      method: method,
      onCategoryChanged: onCategoryChanged,
      onMethodChanged: onMethodChanged,
    );
  }
}
