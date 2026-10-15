import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/dues/utils/dues_rules.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

/// Todos · Me pagan · Yo pago.
class DueFilterToggle extends ConsumerWidget {
  const DueFilterToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppToggle<DueFilter>(
      compact: true,
      selected: ref.watch(dueFilterProvider),
      onSelected: ref.read(dueFilterProvider.notifier).set,
      options: [
        for (final filter in DueFilter.values)
          AppToggleOption(
            value: filter,
            label: filter.label,
            color: switch (filter) {
              DueFilter.income => AppColors.success,
              DueFilter.expense => AppColors.error,
              DueFilter.all => null,
            },
          ),
      ],
    );
  }
}
