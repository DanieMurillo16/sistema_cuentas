import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/features/catalogs/data/catalogs_repository.dart';
import 'package:sistema_cuentas/features/catalogs/models/payment_method.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Medios de pago de la sesión (activos e inactivos) (Nequi, Bancolombia, efectivo…).
final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>(
      PaymentMethodsNotifier.new,
    );

/// Los medios que se pueden elegir al registrar algo (los activos).
final activePaymentMethodsProvider = Provider<AsyncValue<List<PaymentMethod>>>(
  (ref) => mapKeepingData(
    ref.watch(paymentMethodsProvider),
    (items) => [
      for (final item in items)
        if (item.active) item,
    ],
  ),
);

class PaymentMethodsNotifier extends AsyncNotifier<List<PaymentMethod>> {
  @override
  Future<List<PaymentMethod>> build() {
    ref.watch(sessionUserIdProvider);
    return ref.read(catalogsRepositoryProvider).paymentMethods();
  }

  void upsert(PaymentMethod method) {
    final current = state.value;
    if (current == null) return;
    final exists = current.any((m) => m.id == method.id);
    final merged = [
      for (final m in current)
        if (m.id == method.id) method else m,
      if (!exists) method,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    state = AsyncData(merged);
  }
}
