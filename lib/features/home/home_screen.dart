import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/home/widgets/home_content.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_sheet.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_fab.dart';

/// Inicio: balance del mes + historial de movimientos por día + botón «+».
/// pantalla → movementsProvider / monthSummaryProvider → repositorios → API.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: AppFab(
        heroTag: 'home_new_movement',
        icon: Icons.add_rounded,
        tooltip: 'Nuevo movimiento',
        onPressed: () => showNewMovementSheet(context),
      ),
      body: AppAsyncView(
        state: ref.watch(movementsProvider),
        // El vacío lo resuelve el contenido (el balance se sigue viendo).
        isEmpty: (_) => false,
        onRetry: () {
          ref.invalidate(monthSummaryProvider);
          ref.invalidate(movementsProvider);
        },
        builder: (_) => const HomeContent(),
      ),
    );
  }
}
