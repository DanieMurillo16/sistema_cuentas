import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/dues/models/dues_month.dart';
import 'package:sistema_cuentas/features/dues/providers/dues_provider.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_filter_toggle.dart';
import 'package:sistema_cuentas/features/dues/widgets/due_row.dart';
import 'package:sistema_cuentas/features/dues/widgets/dues_summary_cards.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_empty_view.dart';

/// El mes con datos: lo que falta cobrar y pagar, el filtro y cada vencimiento.
/// Tirar hacia abajo vuelve a pedirlo sin vaciar la pantalla.
class DuesList extends ConsumerWidget {
  const DuesList({super.key, required this.month});

  final DuesMonth month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dues = ref.watch(visibleDuesProvider).value ?? const [];
    final hidden = ref.watch(balancesHiddenProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(duesProvider);
        await ref.read(duesProvider.future).then((_) {}, onError: (_) {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(DesignTokens.spaceMd),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  DuesSummaryCards(month: month, hidden: hidden),
                  const SizedBox(height: DesignTokens.spaceMd),
                  const DueFilterToggle(),
                ],
              ),
            ),
          ),
          if (dues.isEmpty)
            const SliverToBoxAdapter(
              child: AppEmptyView(
                icon: Icons.event_available_outlined,
                title: 'Nada de este tipo',
                message: 'No hay vencimientos con ese filtro este mes.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceMd,
              ),
              sliver: SliverList.separated(
                itemCount: dues.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.spaceSm),
                itemBuilder: (context, index) => DueRow(
                  key: ValueKey('due-${dues[index].id}'),
                  due: dues[index],
                  hidden: hidden,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.paddingOf(context).bottom +
                  DesignTokens.fabClearance,
            ),
          ),
        ],
      ),
    );
  }
}
