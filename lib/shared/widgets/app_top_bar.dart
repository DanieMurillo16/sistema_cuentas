import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/providers/balances_hidden_provider.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/brand_logo.dart';
import 'package:sistema_cuentas/shared/widgets/month_selector.dart';
import 'package:sistema_cuentas/shared/widgets/user_avatar.dart';
import 'package:sistema_cuentas/shared/widgets/visibility_toggle_button.dart';

/// Cabecera común de las pestañas: nombre de la vista, selector de mes, ojo
/// para tapar cifras y avatar con la inicial de quien usa la app. Con
/// [showMonth] en falso (Ajustes) no hay selector.
class AppTopBar extends ConsumerWidget {
  const AppTopBar({super.key, required this.title, this.showMonth = true});

  final String title;
  final bool showMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(
      sessionProvider.select((s) => s.value?.user.fullName ?? ''),
    );
    final hidden = ref.watch(balancesHiddenProvider);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceMd,
          vertical: DesignTokens.spaceSm,
        ),
        // El ancho que decide si cabe el logo es el de la cabecera, no el de
        // la pantalla; con texto grande hace falta más.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minWidth = MediaQuery.textScalerOf(context)
                .scale(DesignTokens.headerLogoMinWidth);
            return Row(
              children: [
                if (constraints.maxWidth >= minWidth) ...[
                  const BrandLogo(),
                  const SizedBox(width: DesignTokens.spaceMd),
                ],
                Expanded(
                  child: _Identity(title: title, showMonth: showMonth),
                ),
                VisibilityToggleButton(
                  hidden: hidden,
                  onTap: ref.read(balancesHiddenProvider.notifier).toggle,
                ),
                const SizedBox(width: DesignTokens.spaceSm),
                UserAvatar(name: name),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.title, required this.showMonth});

  final String title;
  final bool showMonth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // El nombre de la vista se lee completo: si no cabe, baja de línea.
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (showMonth) const MonthSelector(),
      ],
    );
  }
}
