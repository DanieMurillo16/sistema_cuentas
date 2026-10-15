import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';

/// Un destino del menú. Los destinos que ve cada usuario (según permisos) los
/// decide el provider de la app; el shell solo los dibuja.
class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Las cuatro pestañas de la app, en orden.
const appDestinations = <AppDestination>[
  AppDestination(
    path: AppRoutes.home,
    label: 'Inicio',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  AppDestination(
    path: AppRoutes.recurring,
    label: 'Pagos recurrentes',
    icon: Icons.event_repeat_outlined,
    selectedIcon: Icons.event_repeat_rounded,
  ),
  AppDestination(
    path: AppRoutes.summary,
    label: 'Resumen',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
  ),
  AppDestination(
    path: AppRoutes.settings,
    label: 'Ajustes',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];
