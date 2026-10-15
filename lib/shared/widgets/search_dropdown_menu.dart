import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/core/utils/text_formatter.dart';

class SearchDropdownMenu<T extends Object> extends StatelessWidget {
  const SearchDropdownMenu({
    super.key,
    required this.width,
    required this.options,
    required this.itemLabel,
    required this.onSelected,
  });
  final double width;
  final List<T> options;
  final String Function(T) itemLabel;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final highlighted = AutocompleteHighlightedOption.of(context);
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: DesignTokens.menuMaxHeight,
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => ListTile(
                dense: true,
                selected: index == highlighted,
                title: Text(
                  formatDisplayText(itemLabel(options[index])),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSelected(options[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
