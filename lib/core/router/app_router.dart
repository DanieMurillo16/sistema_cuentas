import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_cuentas/core/router/app_routes.dart';
import 'package:sistema_cuentas/core/router/fade_page.dart';
import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/features/auth/login_screen.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_min_time_provider.dart';
import 'package:sistema_cuentas/features/auth/splash_screen.dart';
import 'package:sistema_cuentas/features/catalogs/categories_screen.dart';
import 'package:sistema_cuentas/features/catalogs/contacts_screen.dart';
import 'package:sistema_cuentas/features/catalogs/payment_methods_screen.dart';
import 'package:sistema_cuentas/features/home/home_screen.dart';
import 'package:sistema_cuentas/features/movements/movements_list_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_detail_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_form_screen.dart';
import 'package:sistema_cuentas/features/recurring/recurring_screen.dart';
import 'package:sistema_cuentas/features/settings/settings_screen.dart';
import 'package:sistema_cuentas/features/settings/theme_screen.dart';
import 'package:sistema_cuentas/features/summary/summary_screen.dart';
import 'package:sistema_cuentas/features/users/users_screen.dart';
import 'package:sistema_cuentas/shared/navigation/app_destination.dart';
import 'package:sistema_cuentas/shared/navigation/main_shell.dart';
import 'package:sistema_cuentas/shared/providers/session_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // El router se reevalúa cuando la sesión cambia (abrir, cerrar, expirar).
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  // Al cumplirse el tiempo mínimo del splash, se vuelve a decidir adónde ir.
  ref.listen(splashMinTimeProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    // Necesario para que `AppToast` y los diálogos de SmartDialog se coordinen
    // con la navegación.
    observers: [FlutterSmartDialog.observer],
    redirect: (context, state) => _redirect(
      ref.read(sessionProvider),
      state,
      splashHeld: !ref.read(splashMinTimeProvider).hasValue,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => fadePage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => fadePage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.movements,
        redirect: (context, state) =>
            MovementType.tryFromRoute(state.pathParameters['type']) == null
            ? AppRoutes.home
            : null,
        builder: (context, state) => MovementsListScreen(
          type: MovementType.tryFromRoute(state.pathParameters['type'])!,
        ),
      ),
      GoRoute(
        path: AppRoutes.settingsCategories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsMethods,
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsContacts,
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsTheme,
        builder: (context, state) => const ThemeScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsUsers,
        // Solo el administrador (el servidor también lo valida): quien entre
        // por un enlace sin serlo vuelve a Ajustes.
        redirect: (context, state) =>
            ref
                    .read(sessionProvider)
                    .value
                    ?.hasPermission(Permissions.manageUsers) ==
                true
            ? null
            : AppRoutes.settings,
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.recurringNew,
        builder: (context, state) => const RecurringFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.recurringDetail,
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['id'] ?? '') == null
            ? AppRoutes.recurring
            : null,
        builder: (context, state) =>
            RecurringDetailScreen(id: int.parse(state.pathParameters['id']!)),
      ),
      // Una rama por pestaña: al cambiar de una a otra se conserva lo que se
      // estaba haciendo (scroll, filtros) y no hay animación de «empujar».
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => fadePage(
          context: context,
          state: state,
          child: MainShell(
            location: appDestinations[shell.currentIndex].path,
            child: shell,
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.recurring,
                builder: (context, state) => const RecurringScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.summary,
                builder: (context, state) => const SummaryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Sin sesión → login; con sesión → fuera de login y splash. Mientras se
/// recupera la sesión guardada (o si falló por red) se queda en splash; y,
/// aunque ya esté lista, no sale de él hasta cumplir su tiempo mínimo
/// ([splashHeld]).
String? _redirect(
  AsyncValue<Object?> session,
  GoRouterState state, {
  required bool splashHeld,
}) {
  final location = state.uri.path;
  if (splashHeld && location == AppRoutes.splash && !session.hasError) {
    return null;
  }
  if ((session.isLoading && !session.hasValue) || session.hasError) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final signedIn = session.value != null;
  if (!signedIn) return location == AppRoutes.login ? null : AppRoutes.login;
  final inPublicRoute =
      location == AppRoutes.login || location == AppRoutes.splash;
  return inPublicRoute ? AppRoutes.home : null;
}
