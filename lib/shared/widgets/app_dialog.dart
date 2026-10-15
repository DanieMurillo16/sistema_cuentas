import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog_body.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.header,
    required this.content,
    required this.actions,
    this.scrollContent = true,
  });

  final DialogHeader header;
  final Widget content;
  final Widget actions;
  // Los listados con scroll propio conservan un único desplazamiento.
  final bool scrollContent;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(DesignTokens.spaceMd),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      // Dialog ya desplaza el marco; el contenido necesita saber si hay teclado.
      child: MediaQuery(
        data: MediaQuery.of(context),
        child: Theme(
          data: AppTheme.compactForm(Theme.of(context)),
          child: AppDialogBody(
            header: header,
            content: content,
            actions: actions,
            scrollContent: scrollContent,
          ),
        ),
      ),
    );
  }
}
