import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/currency_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/category_donut.dart';
import 'package:sistema_cuentas/features/summary/widgets/category_movements_sheet.dart';
import 'package:sistema_cuentas/features/summary/widgets/donut_legend_tile.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_type_toggle.dart';

/// Categorías del mes en una dona: gastos o ingresos (conmutador) con su total
/// al centro y la leyenda debajo. Tocar una categoría muestra sus movimientos.
class SummaryDonutCard extends StatefulWidget {
  const SummaryDonutCard({super.key, required this.rows, required this.hidden});

  final List<CategoryTotal> rows;
  final bool hidden;

  @override
  State<SummaryDonutCard> createState() => _SummaryDonutCardState();
}

class _SummaryDonutCardState extends State<SummaryDonutCard> {
  // Estado efímero y visual: qué tipo se ve. Permitido con setState.
  var _type = MovementType.expense;

  @override
  Widget build(BuildContext context) {
    final shares = SummaryRules.categoryShares(widget.rows, _type);
    final shown = SummaryRules.topCategories(shares);
    final total = SummaryRules.groupTotal(shares);
    final income = _type.isIncome;
    return SummarySectionCard(
      title: 'Por categoría',
      subtitle: income ? 'De dónde viene tu dinero' : 'En qué se va tu dinero',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SummaryTypeToggle(
            expenseFirst: true,
            selected: _type,
            onSelected: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.all(DesignTokens.spaceMd),
              child: Text('Nada este mes.', textAlign: TextAlign.center),
            )
          else ...[
            Center(
              child: CategoryDonut(
                shares: shown,
                totalCents: total,
                income: income,
                hidden: widget.hidden,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            for (final (i, share) in shown.indexed)
              DonutLegendTile(
                key: ValueKey('donut-${_type.apiValue}-${share.name}'),
                color: AppColors.chart[i % AppColors.chart.length],
                name: share.name,
                amount: formatCents(share.totalCents),
                percent: (share.share * 100).round(),
                hidden: widget.hidden,
                onTap: share.categoryId == null
                    ? null
                    : () => showCategoryMovementsSheet(
                        context,
                        categoryId: share.categoryId!,
                        name: share.name,
                        type: _type,
                      ),
              ),
          ],
        ],
      ),
    );
  }
}
