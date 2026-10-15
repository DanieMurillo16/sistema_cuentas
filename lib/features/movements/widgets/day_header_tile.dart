import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/movements/utils/movement_groups.dart';
import 'package:sistema_cuentas/features/movements/widgets/day_total_button.dart';
import 'package:sistema_cuentas/shared/providers/hidden_sections_provider.dart';

/// Encabezado de un día: «Ayer» o «Domingo, 11 Oct.» y el neto del día. Tocar el
/// neto lo tapa o lo destapa, solo el de ese día (el ojo de la cabecera tapa
/// todos).
class DayHeaderTile extends ConsumerWidget {
  const DayHeaderTile({super.key, required this.entry, required this.hidden});

  final DayHeaderEntry entry;

  /// Si todas las cifras están tapadas (el ojo de la cabecera).
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = HiddenSections.day(entry.date);
    // Tapado por su propio toque o por el ojo de la cabecera.
    final dayHidden = hidden || ref.watch(sectionHiddenProvider(section));
    return Padding(
      padding: const EdgeInsets.only(
        top: DesignTokens.spaceLg,
        bottom: DesignTokens.spaceSm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  entry.label,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.spaceSm),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.5),
              child: DayTotalButton(
                itemKey: entry.date.toIso8601String(),
                label: entry.label,
                text: formatCentsSigned(entry.totalCents),
                income: entry.totalCents >= 0,
                hidden: dayHidden,
                onTap: () =>
                    ref.read(hiddenSectionsProvider.notifier).toggle(section),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
