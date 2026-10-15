import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Marco común; el modo compacto solo cambia el espacio entre acciones.
class DialogActionBar extends StatelessWidget {
  const DialogActionBar({
    super.key,
    required this.children,
    this.compact = false,
  });
  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(
      compact || MediaQuery.viewInsetsOf(context).bottom > 0
          ? DesignTokens.spaceMd
          : DesignTokens.spaceLg,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: Wrap(
      alignment: WrapAlignment.end,
      spacing: compact ? DesignTokens.spaceSm : DesignTokens.spaceMd,
      runSpacing: DesignTokens.spaceSm,
      children: children,
    ),
  );
}
