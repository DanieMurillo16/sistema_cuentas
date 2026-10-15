import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/summary/models/month_summary.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/features/summary/widgets/summary_sections.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';

/// El resumen del mes en secciones: en teléfono una columna; con ancho, dos.
/// Tirar hacia abajo vuelve a pedirlo sin vaciar la pantalla.
class SummaryContent extends ConsumerWidget {
  const SummaryContent({super.key, required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(balancesHiddenProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthSummaryProvider);
        await ref
            .read(monthSummaryProvider.future)
            .then((_) {}, onError: (_) {});
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns =
              constraints.maxWidth >= DesignTokens.compactLayoutWidth;
          final columnWidth = twoColumns
              ? (constraints.maxWidth - DesignTokens.spaceMd * 3) / 2
              : constraints.maxWidth - DesignTokens.spaceMd * 2;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              DesignTokens.spaceMd,
              DesignTokens.spaceMd,
              DesignTokens.spaceMd,
              MediaQuery.paddingOf(context).bottom + DesignTokens.spaceXl,
            ),
            child: SummarySections(
              summary: summary,
              hidden: hidden,
              columnWidth: columnWidth,
            ),
          );
        },
      ),
    );
  }
}
