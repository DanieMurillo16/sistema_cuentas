import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Filas con altura natural: el texto grande no queda atrapado en una grilla.
class ResponsiveCards extends StatelessWidget {
  const ResponsiveCards({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= DesignTokens.expandedLayoutWidth
          ? 3
          : constraints.maxWidth >= DesignTokens.compactLayoutWidth
          ? 2
          : 1;
      return ListView.separated(
        padding: DesignTokens.pagePadding,
        itemCount: (itemCount / columns).ceil(),
        separatorBuilder: (_, _) =>
            const SizedBox(height: DesignTokens.spaceMd),
        itemBuilder: (context, row) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(columns, (column) {
            final index = row * columns + column;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: column == 0 ? 0 : DesignTokens.spaceMd,
                ),
                child: index < itemCount
                    ? itemBuilder(context, index)
                    : const SizedBox(),
              ),
            );
          }),
        ),
      );
    },
  );
}
