import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Lo que se borra y lo que se conserva, dicho sin rodeos (primer paso del
/// diálogo de «Eliminar mis datos»).
class ResetDataConfirmContent extends StatelessWidget {
  const ResetDataConfirmContent({super.key});

  static const erased = [
    'Todos tus ingresos y gastos',
    'Tus pagos recurrentes y sus vencimientos',
    'Tus contactos',
    'Tus categorías y medios de pago (quedan los iniciales, como en una '
        'cuenta nueva)',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vas a empezar desde cero. Se borra para siempre y no se puede '
          'deshacer:',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        for (final item in erased) _Bullet(text: item),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(
          'Se conserva tu usuario y tu contraseña. Al terminar tendrás que '
          'volver a iniciar sesión.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Mientras el servidor borra: el diálogo no se puede cerrar.
class ResetDataLoadingContent extends StatelessWidget {
  const ResetDataLoadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox.square(
          dimension: DesignTokens.progressSize,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: Text(
            'Eliminando tus datos… No cierres la app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// Ya se borró todo: se avisa y se pide volver a entrar.
class ResetDataDoneContent extends StatelessWidget {
  const ResetDataDoneContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tus datos se eliminaron. Debes volver a iniciar sesión para empezar '
      'desde cero.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: AppColors.expense)),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
