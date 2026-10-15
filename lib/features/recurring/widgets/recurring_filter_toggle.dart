import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

/// Activos · Finalizados.
class RecurringFilterToggle extends ConsumerWidget {
  const RecurringFilterToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppToggle<RecurringFilter>(
      compact: true,
      selected: ref.watch(recurringFilterProvider),
      onSelected: ref.read(recurringFilterProvider.notifier).set,
      options: [
        for (final filter in RecurringFilter.values)
          AppToggleOption(value: filter, label: filter.label),
      ],
    );
  }
}
