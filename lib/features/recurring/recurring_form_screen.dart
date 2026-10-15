import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_form.dart';
import 'package:sistema_cuentas/shared/widgets/app_sub_screen_bar.dart';

/// Pantalla completa para crear un pago recurrente.
/// RecurringForm → saveRecurringProvider → RecurringRepository → crear.php
class RecurringFormScreen extends StatelessWidget {
  const RecurringFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppSubScreenBar(
        title: 'Nuevo pago recurrente',
        fallbackPath: AppRoutes.recurring,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.formMaxWidth,
            ),
            child: const RecurringForm(),
          ),
        ),
      ),
    );
  }
}
