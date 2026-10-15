import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/providers/home_entries_provider.dart';
import 'package:sistema_cuentas/features/home/widgets/home_balance_section.dart';
import 'package:sistema_cuentas/features/home/widgets/home_empty_message.dart';
import 'package:sistema_cuentas/features/home/widgets/home_filter_header.dart';
import 'package:sistema_cuentas/features/initial_balance/providers/initial_balance_prompt_provider.dart';
import 'package:sistema_cuentas/features/initial_balance/widgets/initial_balance_card.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_entries_sliver.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_provider.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_appear.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';

/// Un solo scroll: balance, conmutador fijo (todos, ingresos, gastos) e historial por día. Tirar hacia
/// abajo vuelve a pedir el mes y sus totales sin vaciar la pantalla.
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(homeEntriesProvider);
    final hidden = ref.watch(balancesHiddenProvider);
    final filter = ref.watch(homeTypeFilterProvider);
    // La primera vez, con todo vacío, se invita a registrar el saldo inicial.
    final showInitialBalance =
        filter == null && ref.watch(showInitialBalancePromptProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(monthSummaryProvider);
        ref.invalidate(movementsProvider);
        // El error ya se muestra en pantalla: aquí solo se termina el gesto.
        await ref.read(movementsProvider.future).then((_) {}, onError: (_) {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.all(DesignTokens.spaceMd),
            sliver: SliverToBoxAdapter(child: HomeBalanceSection()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMd,
            ),
            sliver: const HomeFilterHeader(),
          ),
          if (entries.isEmpty && showInitialBalance)
            const SliverPadding(
              padding: EdgeInsets.all(DesignTokens.spaceMd),
              sliver: SliverToBoxAdapter(
                child: AppAppear(
                  child: AppPulse(beats: 6, child: InitialBalanceCard()),
                ),
              ),
            )
          else if (entries.isEmpty)
            // La primera vez el «sin movimientos» sobra: la invitación ya dice qué hacer.
            SliverToBoxAdapter(child: HomeEmptyMessage(filter: filter))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceMd,
              ),
              sliver: MovementEntriesSliver(entries: entries, hidden: hidden),
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
