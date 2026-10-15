import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/utils/json_helpers.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/shared/widgets/kpi_cards_row.dart';

/// Lo que falta del mes: «Por cobrar» (me deben) y «Por pagar» (debo). Las
/// cifras las calcula el servidor; aquí solo se muestran.
class DuesSummaryCards extends StatelessWidget {
  const DuesSummaryCards({
    super.key,
    required this.month,
    required this.hidden,
  });

  final DuesMonth month;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final income = month.totalsFor(MovementType.income);
    final expense = month.totalsFor(MovementType.expense);
    return KpiCardsRow(
      gridOnPhone: true,
      cards: [
        KpiCardData(
          title: 'Por cobrar',
          amount: centsToPesos(income.balanceCents),
          hidden: hidden,
          icon: Icons.south_west_rounded,
          color: AppColors.income,
        ),
        KpiCardData(
          title: 'Por pagar',
          amount: centsToPesos(expense.balanceCents),
          hidden: hidden,
          icon: Icons.north_east_rounded,
          color: AppColors.expense,
        ),
      ],
    );
  }
}
