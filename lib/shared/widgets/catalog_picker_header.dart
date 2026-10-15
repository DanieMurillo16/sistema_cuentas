import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';

/// Título del selector y su buscador.
class CatalogPickerHeader extends StatelessWidget {
  const CatalogPickerHeader({
    super.key,
    required this.title,
    required this.controller,
    required this.onChanged,
    this.searchable = true,
  });

  final String title;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// Con pocas opciones el buscador sobra.
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (searchable) ...[
          const SizedBox(height: DesignTokens.spaceMd),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Buscar ${title.toLowerCase()}...',
              suffixIcon: const Icon(Icons.search_rounded),
            ),
          ),
        ],
      ],
    );
  }
}
