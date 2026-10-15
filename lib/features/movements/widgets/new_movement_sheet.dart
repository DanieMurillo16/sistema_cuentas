import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_form.dart';
import 'package:sistema_cuentas/features/movements/widgets/movement_type_picker.dart';
import 'package:sistema_cuentas/features/movements/widgets/new_movement_header.dart';
import 'package:sistema_cuentas/shared/widgets/fade_through_transition.dart';

/// Hoja inferior del botón «+»: primero se elige Ingreso o Gasto y, en la misma
/// hoja, se llena el formulario. Mide lo que midan sus campos (como mucho
/// `sheetMaxHeightFactor` de la pantalla): arriba sigue viéndose el balance, que
/// es adonde «vuela» el monto al registrar.
Future<void> showNewMovementSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // En el navegador raíz: así queda por encima de la píldora del menú (el
    // navegador de la pestaña vive debajo de ella).
    useRootNavigator: true,
    builder: (_) => const NewMovementSheet(),
  );
}

class NewMovementSheet extends StatefulWidget {
  const NewMovementSheet({super.key});

  @override
  State<NewMovementSheet> createState() => _NewMovementSheetState();
}

class _NewMovementSheetState extends State<NewMovementSheet> {
  // Estado efímero y visual: qué paso se ve. Permitido con setState.
  MovementType? _type;

  void _select(MovementType? type) {
    // El teclado se cierra primero: volver con él abierto movía la hoja dos
    // veces (el cambio de paso y luego el teclado al irse).
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _type = type);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Alto continuo: el menor entre lo normal y lo que deja libre el
        // teclado. Con un cambio brusco entre los dos (como antes) la hoja
        // saltaba al abrir y al cerrar el teclado.
        final inset = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.min(
                constraints.maxHeight * DesignTokens.sheetMaxHeightFactor,
                constraints.maxHeight - inset,
              ),
            ),
            child: _Steps(
              type: _type,
              onSelect: _select,
              keyboardOpen: inset > 0,
            ),
          ),
        );
      },
    );
  }
}

const _followKeyboard = Duration(milliseconds: 1);

/// Mientras un paso se va y el otro entra, solo el que entra da el tamaño: el
/// que sale queda pegado arriba, fundiéndose, y recortado por el `AnimatedSize`.
/// Con los dos dando tamaño, la hoja esperaba a que el viejo se fuera para
/// empezar a achicarse (dos movimientos seguidos).
Widget _currentSizesTheStack(Widget? current, List<Widget> previous) => Stack(
  alignment: Alignment.topCenter,
  children: [
    for (final old in previous)
      Positioned(top: 0, left: 0, right: 0, child: old),
    ?current,
  ],
);

class _Steps extends StatelessWidget {
  const _Steps({
    required this.type,
    required this.onSelect,
    required this.keyboardOpen,
  });

  final MovementType? type;
  final ValueChanged<MovementType?> onSelect;

  /// Con el teclado visible el tamaño sigue al teclado cuadro a cuadro: animarlo
  /// también lo haría ir un paso atrás. (No puede ser cero: `AnimatedSize`
  /// terminaría su animación dentro del propio layout y fallaría.)
  final bool keyboardOpen;

  @override
  Widget build(BuildContext context) {
    final current = type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NewMovementHeader(type: current, onBack: () => onSelect(null)),
        Flexible(
          child: AnimatedSize(
            duration: keyboardOpen
                ? _followKeyboard
                : motionDuration(context, DesignTokens.animationNormal),
            curve: DesignTokens.curve,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: motionDuration(context, DesignTokens.animationNormal),
              transitionBuilder: fadeThroughTransition,
              layoutBuilder: _currentSizesTheStack,
              child: current == null
                  ? MovementTypePicker(
                      key: const ValueKey('picker'),
                      onSelected: onSelect,
                    )
                  : MovementForm(key: ValueKey(current), type: current),
            ),
          ),
        ),
      ],
    );
  }
}
