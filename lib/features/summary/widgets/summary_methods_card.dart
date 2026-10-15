import 'package:flutter/material.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/utils/summary_rules.dart';
import 'package:sistema_cuentas/features/summary/widgets/method_flow_tile.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_section_card.dart';

/// Por medio de pago: lo que entró, lo que salió y lo que dejó cada uno
/// (Nequi, Bancolombia, efectivo…).
class SummaryMethodsCard extends StatelessWidget {
  const SummaryMethodsCard({
    super.key,
    required this.rows,
    required this.hidden,
  });

  final List<MethodTotal> rows;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final flows = SummaryRules.methodFlows(rows);
    return SummarySectionCard(
      title: 'Por medio de pago',
      subtitle: 'Lo que dejó cada uno este mes',
      child: flows.isEmpty
          ? const Text('Sin movimientos este mes.')
          : Column(
              children: [
                for (final flow in flows)
                  MethodFlowTile(
                    key: ValueKey('method-${flow.methodId}'),
                    flow: flow,
                    hidden: hidden,
                  ),
              ],
            ),
    );
  }
}
