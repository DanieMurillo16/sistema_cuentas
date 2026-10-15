import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/catalogs/models/category.dart';
import 'package:sistema_cuentas/features/catalogs/providers/save_catalog_providers.dart';
import 'package:sistema_cuentas/shared/widgets/confirm_action_dialog.dart';

/// «Eliminar» en el pie del diálogo de editar una categoría: pide confirmar y,
/// si se acepta, la elimina (el diálogo se cierra al terminar).
class CategoryDeleteButton extends ConsumerWidget {
  const CategoryDeleteButton({
    super.key,
    required this.category,
    required this.enabled,
  });

  final Category category;
  final bool enabled;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'Eliminar categoría',
        message:
            'Ya no podrás usar «${category.name}» en nada nuevo. Lo registrado '
            'se conserva.',
        confirmLabel: 'Eliminar',
        icon: Icons.delete_outline_rounded,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(deleteCategoryProvider.notifier).delete(category.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = Theme.of(context).colorScheme.error;
    final deleting = ref.watch(
      deleteCategoryProvider.select((s) => s.isLoading),
    );
    return OutlinedButton.icon(
      onPressed: enabled ? () => _delete(context, ref) : null,
      style: OutlinedButton.styleFrom(foregroundColor: error),
      icon: deleting
          ? const SizedBox.square(
              dimension: DesignTokens.progressSize,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline_rounded),
      label: const Text('Eliminar'),
    );
  }
}
