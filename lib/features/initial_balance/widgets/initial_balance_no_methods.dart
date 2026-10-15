import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';

/// Sin medios de pago activos no hay dónde poner el saldo: lo dice y lleva a
/// crearlos.
class InitialBalanceNoMethods extends StatelessWidget {
  const InitialBalanceNoMethods({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aún no tienes medios de pago. Crea al menos uno (Nequi, '
          'Bancolombia, efectivo…) para registrar tu saldo.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.push(AppRoutes.settingsMethods);
          },
          child: const Text('Ir a Medios de pago'),
        ),
      ],
    );
  }
}
