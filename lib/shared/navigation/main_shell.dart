import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/providers/app_preload_provider.dart';
import 'package:sistema_cuentas/shared/widgets/app_shell.dart';
import 'package:sistema_cuentas/shared/widgets/app_top_bar.dart';

/// El marco de las cuatro pestañas: el router lo usa como `ShellRoute`. Al
/// montarse arranca la precarga de datos en segundo plano.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    ref.read(appPreloadProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      destinations: appDestinations,
      currentPath: widget.location,
      onSelected: (destination) => context.go(destination.path),
      header: AppTopBar(
        title: _titleFor(widget.location),
        showMonth: widget.location != AppRoutes.settings,
      ),
      child: widget.child,
    );
  }

  /// El nombre de la pestaña actual; si la ruta no es una pestaña, la primera.
  String _titleFor(String location) => appDestinations
      .firstWhere(
        (d) => d.path == location,
        orElse: () => appDestinations.first,
      )
      .label;
}
