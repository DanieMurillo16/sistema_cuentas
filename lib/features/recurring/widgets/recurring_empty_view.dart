import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_empty_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_pulse.dart';

/// Sin acuerdos: invita a crear el primero (o avisa que no hay finalizados).
class RecurringEmptyView extends StatelessWidget {
  const RecurringEmptyView({super.key, required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceXl),
      child: AppEmptyView(
        icon: Icons.event_repeat_outlined,
        title: finished
            ? 'Ningún pago finalizado'
            : 'No tienes pagos recurrentes',
        message: finished ? 'Los acuerdos que cierres aparecerán aquí.' : 'Crea los pagos que se repiten cada mes: lo que te pagan y lo que pagas.',
        action: finished
            ? null
            // Late sin parar y bien visible: es lo único que hay que hacer aquí.
            : AppPulse(
                scale: 1.1,
                beat: const Duration(milliseconds: 900),
                child: FilledButton(
                  onPressed: () => context.push(AppRoutes.recurringNew),
                  child: const Text('Crear mi primer pago recurrente'),
                ),
              ),
      ),
    );
  }
}
