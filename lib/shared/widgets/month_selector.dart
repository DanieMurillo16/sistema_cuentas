import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/motion.dart';
import 'package:sistema_cuentas/shared/providers/selected_month_provider.dart';

/// ‹ OCT DE 2026 ›: cambia el mes que ven todas las pestañas.
class MonthSelector extends ConsumerWidget {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final canGoNext = ref.watch(canGoNextMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(letterSpacing: 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Mes anterior',
          onPressed: notifier.previous,
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: motionDuration(context, DesignTokens.animationFast),
            child: Text(
              formatMonthYear(month),
              key: ValueKey(month),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Mes siguiente',
          onPressed: canGoNext ? notifier.next : null,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(
        width: DesignTokens.actionSize,
        height: DesignTokens.actionSize,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: AppColors.muted),
    );
  }
}
