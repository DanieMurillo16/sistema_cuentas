import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_detail_body.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_sub_screen_bar.dart';

/// Detalle de un pago recurrente: ficha, historial y «Finalizar».
/// pantalla → recurringDetailProvider(id) → RecurringRepository → detalle.php
class RecurringDetailScreen extends ConsumerWidget {
  const RecurringDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const AppSubScreenBar(
        title: 'Pago recurrente',
        fallbackPath: AppRoutes.recurring,
      ),
      body: SafeArea(
        child: Center(
          // Fuera del menú no hay tope de ancho: la ficha no se estira.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.formMaxWidth,
            ),
            child: AppAsyncView(
              state: ref.watch(recurringDetailProvider(id)),
              isEmpty: (_) => false,
              onRetry: () => ref.invalidate(recurringDetailProvider(id)),
              builder: (detail) => RecurringDetailBody(detail: detail),
            ),
          ),
        ),
      ),
    );
  }
}
