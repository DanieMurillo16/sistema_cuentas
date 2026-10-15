import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';
import 'package:sistema_cuentas/features/movements/models/movement.dart';
import 'package:sistema_cuentas/shared/widgets/dot_separated_text.dart';

/// La segunda línea de una fila: «categoría · medio» a la izquierda y, pegada a
/// la esquina, la hora en que se registró (si el servidor la manda).
class MovementTileDetail extends StatelessWidget {
  const MovementTileDetail({super.key, required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final createdAt = movement.createdAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DotSeparatedText(
            parts: [
              formatDisplayText(movement.category),
              formatDisplayText(movement.method),
            ],
          ),
        ),
        if (createdAt != null) ...[
          const SizedBox(width: DesignTokens.spaceSm),
          Text(
            formatClock(createdAt),
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
