import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/movements/providers/movements_filter_provider.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_entries_sliver.dart';
import 'package:sistema_cuentas/features/movements/widgets/movements_total_header.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';

/// La lista con datos: el total del filtro y los movimientos por día. Todo sale
/// de providers derivados, no se calcula aquí.
class MovementsListBody extends ConsumerWidget {
  const MovementsListBody({super.key, required this.type});

  final MovementType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(filteredEntriesProvider(type));
    final hidden = ref.watch(balancesHiddenProvider);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: MovementsTotalHeader(
            type: type,
            count:
                ref.watch(filteredMovementsProvider(type)).value?.length ?? 0,
            totalCents: ref.watch(filteredTotalProvider(type)),
            hidden: hidden,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          sliver: MovementEntriesSliver(entries: entries, hidden: hidden),
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
