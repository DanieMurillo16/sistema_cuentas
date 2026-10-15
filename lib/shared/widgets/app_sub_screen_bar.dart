import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Barra de una pantalla completa (formularios, detalles). La flecha vuelve
/// atrás; si no hay a dónde volver (se recargó la página en esa dirección) va a
/// [fallbackPath].
class AppSubScreenBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSubScreenBar({
    super.key,
    required this.title,
    required this.fallbackPath,
  });

  final String title;
  final String fallbackPath;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: 'Atrás',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(fallbackPath),
      ),
    );
  }
}
