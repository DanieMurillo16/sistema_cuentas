import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: DesignTokens.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: DesignTokens.placeholderIconSize),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: DesignTokens.spaceLg),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesignTokens.emptyActionMaxWidth,
                ),
                child: action!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
