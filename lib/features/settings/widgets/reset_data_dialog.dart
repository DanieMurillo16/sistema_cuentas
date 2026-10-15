import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/services/app_toast.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/features/settings/providers/reset_data_provider.dart';
import 'package:sistema_cuentas/features/settings/widgets/reset_data_content.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_dialog.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_actions.dart';
import 'package:sistema_cuentas/shared/widgets/dialog_header.dart';

/// «Eliminar mis datos»: confirmar → eliminando → aviso y volver al login. El
/// diálogo no se puede cerrar mientras borra ni cuando ya borró (solo «Aceptar»,
/// que cierra la sesión).
Future<void> showResetDataDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => const ResetDataDialog(),
);

class ResetDataDialog extends ConsumerStatefulWidget {
  const ResetDataDialog({super.key});

  @override
  ConsumerState<ResetDataDialog> createState() => _ResetDataDialogState();
}

class _ResetDataDialogState extends ConsumerState<ResetDataDialog> {
  @override
  void initState() {
    super.initState();
    // Si falla, el aviso en español y el diálogo vuelve a la confirmación.
    ref.listenManual(resetDataProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasError) {
        AppToast.error(userErrorMessage(next.error));
      }
    });
  }

  void _accept() {
    // Se toma el notifier antes de cerrar: el diálogo se desmonta al hacerlo.
    final session = ref.read(sessionProvider.notifier);
    Navigator.of(context).pop();
    session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetDataProvider);
    final loading = state.isLoading;
    final done = state.value == true && !loading;
    return PopScope(
      canPop: !loading && !done,
      child: AppDialog(
        header: DialogHeader(
          icon: done ? Icons.check_circle_outline : Icons.delete_sweep_outlined,
          color: done ? AppColors.success : AppColors.expense,
          title: done ? 'Datos eliminados' : 'Eliminar todos mis datos',
          subtitle: done ? null : 'Empezar desde cero',
          closeEnabled: !loading && !done,
          onClose: () => Navigator.of(context).pop(),
        ),
        content: loading
            ? const ResetDataLoadingContent()
            : done
            ? const ResetDataDoneContent()
            : const ResetDataConfirmContent(),
        actions: done
            ? DialogActions(
                onConfirm: _accept,
                confirmLabel: 'Aceptar',
                confirmIcon: Icons.check_rounded,
                showCancel: false,
              )
            : DialogActions(
                onConfirm: () => ref.read(resetDataProvider.notifier).reset(),
                confirmLabel: 'Sí, eliminar todo',
                confirmIcon: Icons.delete_forever_outlined,
                destructive: true,
                isLoading: loading,
              ),
      ),
    );
  }
}
