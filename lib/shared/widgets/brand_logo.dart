import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/brand_mark_painter.dart';

/// El icono de la app: cuadro redondeado con el degradado de la marca y el
/// billete con «$».
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = DesignTokens.headerLogoSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.balanceStart, AppColors.balanceEnd],
        ),
      ),
      child: SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(size * DesignTokens.logoPaddingRatio),
          child: CustomPaint(
            painter: BrandMarkPainter(color: AppColors.onBrand),
          ),
        ),
      ),
    );
  }
}
