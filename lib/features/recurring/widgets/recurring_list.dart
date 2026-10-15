import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/utils/recurring_rules.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_empty_view.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_filter_toggle.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_row.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';

/// Mis pagos recurrentes: el filtro Activos/Finalizados y la lista. Si no hay
/// ninguno, invita a crear el primero.
class RecurringList extends ConsumerWidget {
  const RecurringList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(visibleRecurringProvider).value ?? const [];
    final filter = ref.watch(recurringFilterProvider);
    final hidden = ref.watch(balancesHiddenProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recurringListProvider);
        await ref
            .read(recurringListProvider.future)
            .then((_) {}, onError: (_) {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.all(DesignTokens.spaceMd),
            sliver: SliverToBoxAdapter(child: RecurringFilterToggle()),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: RecurringEmptyView(
                finished: filter == RecurringFilter.finished,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceMd,
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.spaceSm),
                itemBuilder: (context, index) => RecurringRow(
                  key: ValueKey('recurring-${items[index].id}'),
                  payment: items[index],
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
