import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_fab.dart';
import 'package:sistema_cuentas/shared/widgets/app_sub_screen_bar.dart';

/// Pantalla de una lista que se administra (Ajustes): barra con «atrás»,
/// cuatro estados, lista por demanda y, si se puede crear, un botón «+».
class ManageListScaffold<T> extends StatelessWidget {
  const ManageListScaffold({
    super.key,
    required this.title,
    required this.state,
    required this.itemBuilder,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onCreate,
    this.createTooltip = 'Nuevo',
  });

  final String title;
  final AsyncValue<List<T>> state;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;

  /// Sin él (la persona no tiene permiso) la lista es solo de lectura.
  final VoidCallback? onCreate;
  final String createTooltip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppSubScreenBar(title: title, fallbackPath: AppRoutes.settings),
      floatingActionButton: onCreate == null
          ? null
          : AppFab(
              heroTag: 'manage_$title',
              icon: Icons.add_rounded,
              tooltip: createTooltip,
              onPressed: onCreate!,
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DesignTokens.formMaxWidth,
            ),
            child: AppAsyncView<List<T>>(
              state: state,
              isEmpty: (items) => items.isEmpty,
              emptyTitle: emptyTitle,
              emptyMessage: emptyMessage,
              onRetry: onRetry,
              builder: (items) => ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.spaceMd,
                  DesignTokens.spaceMd,
                  DesignTokens.spaceMd,
                  DesignTokens.fabClearance,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.spaceSm),
                itemBuilder: (context, index) =>
                    itemBuilder(context, items[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
