import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/features/movements/providers/save_movement_provider.dart';
import 'package:sistema_cuentas/shared/widgets/fade_through_transition.dart';

/// Título de la hoja «+». En el formulario suma una flecha para volver a elegir
/// entre Ingreso y Gasto; mientras se guarda queda apagada (volver desmontaría
/// el formulario y se perdería el aviso del resultado).
class NewMovementHeader extends ConsumerWidget {
  const NewMovementHeader({
    super.key,
    required this.type,
    required this.onBack,
  });

  final MovementType? type;
  final VoidCallback onBack;

  String get _title => switch (type) {
    null => 'Nuevo movimiento',
    MovementType.income => 'Nuevo ingreso',
    MovementType.expense => 'Nuevo gasto',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = ref.watch(saveMovementProvider.select((s) => s.isLoading));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      // Alto fijo (el de la flecha): con o sin flecha la hoja no se mueve. El
      // título y la flecha cambian juntos, con fundido, a la vez que el cuerpo.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: AnimatedSwitcher(
          duration: motionDuration(context, DesignTokens.animationNormal),
          transitionBuilder: fadeThroughTransition,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.centerLeft,
            children: [
              for (final old in previous)
                Positioned(left: 0, right: 0, child: old),
              ?current,
            ],
          ),
          child: Row(
            key: ValueKey(type),
            children: [
              if (type != null)
                IconButton(
                  tooltip: 'Volver',
                  onPressed: saving ? null : onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(
                child: Text(
                  _title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
