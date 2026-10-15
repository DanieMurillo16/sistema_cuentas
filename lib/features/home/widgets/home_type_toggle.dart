import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/shared/utils/movement_type_style.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

/// Todos · Ingresos · Gastos: qué ve el historial. Ingresos en verde y gastos
/// en rojo, como en el resto de la app.
class HomeTypeToggle extends ConsumerWidget {
  const HomeTypeToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppToggle<MovementType?>(
      compact: compact,
      selected: ref.watch(homeTypeFilterProvider),
      onSelected: ref.read(homeTypeFilterProvider.notifier).set,
      options: [
        const AppToggleOption(value: null, label: 'Todos'),
        AppToggleOption(
          value: MovementType.income,
          label: 'Ingresos',
          color: MovementType.income.fill,
        ),
        AppToggleOption(
          value: MovementType.expense,
          label: 'Gastos',
          color: MovementType.expense.fill,
        ),
      ],
    );
  }
}
