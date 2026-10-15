import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/providers/summary_trend_provider.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/method_comparison_tile.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_type_toggle.dart';

/// Por dónde entra (o sale) el dinero: cada medio de pago este mes frente al
/// mes pasado. Lo que el mes pasado no tuvo no se muestra: se ve solo este mes.
class MethodComparisonCard extends ConsumerStatefulWidget {
  const MethodComparisonCard({
    super.key,
    required this.summary,
    required this.hidden,
  });

  final MonthSummary summary;
  final bool hidden;

  @override
  ConsumerState<MethodComparisonCard> createState() =>
      _MethodComparisonCardState();
}

class _MethodComparisonCardState extends ConsumerState<MethodComparisonCard> {
  // Estado efímero y visual: qué tipo se ve. Permitido con setState.
  var _type = MovementType.income;

  @override
  Widget build(BuildContext context) {
    final previous = ref.watch(previousMonthSummaryProvider).value;
    final rows = SummaryRules.methodComparison(
      current: widget.summary.byMethod,
      previous: previous?.byMethod ?? const [],
      type: _type,
    );
    final highest = rows.fold<int>(
      0,
      (max, r) => [
        max,
        r.currentCents,
        r.previousCents,
      ].reduce((a, b) => a > b ? a : b),
    );
    final income = _type.isIncome;
    return SummarySectionCard(
      title: income ? 'Por dónde entra' : 'Por dónde sale',
      subtitle: rows.any((r) => r.previousCents > 0)
          ? 'Cada medio de pago, este mes y el pasado'
          : 'Cada medio de pago, este mes',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryTypeToggle(
            selected: _type,
            onSelected: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(DesignTokens.spaceMd),
              child: Text(
                'Nada este mes ni el pasado.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final row in rows)
              MethodComparisonTile(
                key: ValueKey('cmp-${_type.apiValue}-${row.methodId}'),
                comparison: row,
                highest: highest,
                income: income,
                hidden: widget.hidden,
              ),
        ],
      ),
    );
  }
}
