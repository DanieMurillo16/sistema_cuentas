import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/catalogs/providers/categories_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/contacts_provider.dart';
import 'package:sistema_cuentas/features/catalogs/providers/payment_methods_provider.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

/// Precarga al entrar: pide lo que van a necesitar las pestañas, **por turnos y
/// en segundo plano** (primero lo de Inicio y el resumen, luego los catálogos que
/// necesita la hoja «+», y después vencimientos, acuerdos y contactos). Así, al cambiar de pestaña o abrir un formulario los
/// datos ya están. Nadie observa su progreso: no reconstruye el menú, y un
/// fallo aquí no se muestra (la pantalla que lo necesite volverá a pedirlo y
/// resolverá su propio error).
///
/// Se activa con `ref.read` al montar el menú; si cambia la cuenta, se repite.
final appPreloadProvider = Provider<void>((ref) {
  if (ref.watch(sessionUserIdProvider) == null) return;
  unawaited(_preload(ref));
});

Future<void> _preload(Ref ref) async {
  final steps = <Future<Object?> Function()>[
    () => ref.read(monthSummaryProvider.future),
    () => ref.read(movementsProvider.future),
    () => ref.read(categoriesProvider.future),
    () => ref.read(paymentMethodsProvider.future),
    () => ref.read(duesProvider.future),
    () => ref.read(recurringListProvider.future),
    () => ref.read(contactsProvider.future),
  ];
  for (final step in steps) {
    if (!ref.mounted) return;
    try {
      await step();
    } catch (_) {
      // Sin red o sin permiso: se ignora; la pantalla lo pedirá cuando lo use.
    }
  }
}
