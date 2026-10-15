import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_stat_tile.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/summary_totals.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';

/// Las dos tarjetas bajo el balance: Ingresos (verde) y Gastos (rojo). Al
/// tocarlas se abre la lista de ese tipo con buscador y filtros. Cada una
/// trae «Detalle»: un despegable (cerrado al empezar, uno por tarjeta) con lo
/// de cada medio de pago.
class BalanceStatsRow extends StatefulWidget {
  const BalanceStatsRow({
    super.key,
    required this.totals,
    required this.hidden,
    this.methods = const [],
    this.incomeKey,
    this.expenseKey,
    this.onIncomeTap,
    this.onExpenseTap,
  });

  final SummaryTotals totals;
  final bool hidden;
  final List<MethodTotal> methods;
  final Key? incomeKey;
  final Key? expenseKey;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;

  @override
  State<BalanceStatsRow> createState() => _BalanceStatsRowState();
}

class _BalanceStatsRowState extends State<BalanceStatsRow> {
  // Estado efímero y visual: qué despegables están abiertos. Cada tarjeta abre
  // y cierra el suyo; no se afectan entre sí.
  final _open = <MovementType>{};

  void _toggle(MovementType type) => setState(() {
    if (!_open.remove(type)) _open.add(type);
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      // Cada tarjeta mide lo suyo: abrir una no estira a la otra.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _tile(MovementType.income)),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(child: _tile(MovementType.expense)),
      ],
    );
  }

  BalanceStatTile _tile(MovementType type) => BalanceStatTile(
    anchorKey: type.isIncome ? widget.incomeKey : widget.expenseKey,
    type: type,
    cents: type.isIncome
        ? widget.totals.incomeTotalCents
        : widget.totals.expenseTotalCents,
    hidden: widget.hidden,
    methods: SummaryRules.methodsOf(widget.methods, type),
    methodsExpanded: _open.contains(type),
    onToggleMethods: () => _toggle(type),
    onTap: type.isIncome ? widget.onIncomeTap : widget.onExpenseTap,
  );
}
