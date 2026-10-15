import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/recurring/models/recurring_detail.dart';
import 'package:sistema_cuentas/features/recurring/widgets/deleted_category_notice.dart';
import 'package:sistema_cuentas/features/recurring/widgets/due_history_tile.dart';
import 'package:sistema_cuentas/features/recurring/widgets/finish_recurring_dialog.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_summary_card.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';

/// El detalle con datos: la ficha, «Finalizar» (si sigue activo) y el
/// historial mes a mes (por demanda).
class RecurringDetailBody extends ConsumerWidget {
  const RecurringDetailBody({super.key, required this.detail});

  final RecurringDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(balancesHiddenProvider);
    final payment = detail.payment;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              RecurringSummaryCard(payment: payment, hidden: hidden),
              DeletedCategoryNotice(categoryId: payment.categoryId),
              if (payment.active) ...[
                const SizedBox(height: DesignTokens.spaceMd),
                OutlinedButton.icon(
                  onPressed: () => showFinishRecurringDialog(context, payment),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Finalizar'),
                ),
              ],
              const SizedBox(height: DesignTokens.spaceLg),
              Text('Historial', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: DesignTokens.spaceSm),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          sliver: SliverList.separated(
            itemCount: detail.history.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: DesignTokens.spaceSm),
            itemBuilder: (context, index) => DueHistoryTile(
              key: ValueKey('history-${detail.history[index].id}'),
              item: detail.history[index],
              isIncome: payment.isIncome,
              hidden: hidden,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).bottom + DesignTokens.spaceXl,
          ),
        ),
      ],
    );
  }
}
