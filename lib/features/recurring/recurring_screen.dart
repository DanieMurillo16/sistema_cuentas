import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/dues/widgets/dues_view.dart';
import 'package:sistema_cuentas/features/recurring/providers/recurring_list_provider.dart';
import 'package:sistema_cuentas/features/recurring/widgets/recurring_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_fab.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle.dart';
import 'package:sistema_cuentas/shared/widgets/app_toggle_option.dart';

enum _Section { thisMonth, agreements }

/// Pagos recurrentes: «Este mes» (quién pagó y quién no, con el pago desde la
/// fila) y «Acuerdos» (los pagos recurrentes y su detalle).
/// pantalla → duesProvider / recurringListProvider → repositorios → API.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  // Estado efímero y visual: permitido con setState.
  var _section = _Section.thisMonth;

  @override
  Widget build(BuildContext context) {
    // En «Acuerdos», sin ninguno, la invitación a crear el primero ya hace lo
    // mismo que el botón flotante: no se muestran los dos.
    final inviteShown =
        _section == _Section.agreements &&
        ref.watch(showRecurringInviteProvider);
    return Scaffold(
      floatingActionButton: inviteShown
          ? null
          : AppFab(
              heroTag: 'recurring_new',
              icon: Icons.add_rounded,
              tooltip: 'Nuevo pago recurrente',
              onPressed: () => context.push(AppRoutes.recurringNew),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceMd,
              DesignTokens.spaceMd,
              DesignTokens.spaceMd,
              0,
            ),
            child: AppToggle<_Section>(
              selected: _section,
              onSelected: (value) => setState(() => _section = value),
              options: const [
                AppToggleOption(value: _Section.thisMonth, label: 'Este mes'),
                AppToggleOption(value: _Section.agreements, label: 'Acuerdos'),
              ],
            ),
          ),
          Expanded(
            child: _section == _Section.thisMonth
                ? const DuesView()
                : const RecurringView(),
          ),
        ],
      ),
    );
  }
}
