import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/home/widgets/balance_card.dart';
import 'package:sistema_cuentas/features/summary/providers/month_summary_provider.dart';
import 'package:sistema_cuentas/shared/providers/hidden_sections_provider.dart';
import 'package:sistema_cuentas/shared/providers/fly_targets_provider.dart';

/// El balance del mes con sus propios estados: cargando (solo la primera vez),
/// error con «Reintentar» y datos. Al refrescar conserva la cifra que se ve.
class HomeBalanceSection extends ConsumerWidget {
  const HomeBalanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(sectionHiddenProvider(HiddenSections.balanceCard));
    final targets = ref.watch(flyTargetsProvider);
    return ref
        .watch(monthSummaryProvider)
        .when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          data: (summary) => BalanceCard(
            totals: summary.totals,
            hidden: hidden,
            methods: summary.byMethod,
            onToggleHidden: () => ref
                .read(hiddenSectionsProvider.notifier)
                .toggle(HiddenSections.balanceCard),
            incomeKey: targets.income,
            expenseKey: targets.expense,
            onIncomeTap: () => context.push(
              AppRoutes.movementsFor(MovementType.income.routeName),
            ),
            onExpenseTap: () => context.push(
              AppRoutes.movementsFor(MovementType.expense.routeName),
            ),
          ),
          loading: () => const _BalanceMessage(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _BalanceMessage(
            child: Column(
              children: [
                Text(userErrorMessage(error), textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.spaceSm),
                TextButton(
                  onPressed: () => ref.invalidate(monthSummaryProvider),
                  child: const Text('Intentar nuevamente'),
                ),
              ],
            ),
          ),
        );
  }
}

class _BalanceMessage extends StatelessWidget {
  const _BalanceMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Mide lo mismo que la tarjeta con datos: al llegar la cifra no salta.
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: DesignTokens.balanceCardMinHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Center(child: child),
        ),
      ),
    );
  }
}
