/// Todas las rutas como constantes, en un solo lugar.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';

  // Pestañas del menú
  static const home = '/';
  static const recurring = '/recurring';
  static const summary = '/summary';
  static const settings = '/settings';

  // Pantallas completas (sin menú)
  static const movements = '/movements/:type';
  static const settingsCategories = '/settings-categories';
  static const settingsMethods = '/settings-methods';
  static const settingsContacts = '/settings-contacts';
  static const settingsUsers = '/settings-users';
  static const settingsTheme = '/settings-theme';
  static const recurringNew = '/recurring-new';
  static const recurringDetail = '/recurring-detail/:id';

  /// Ruta de la lista de ingresos o de gastos (`income` / `expense`).
  static String movementsFor(String routeName) => '/movements/$routeName';

  static String recurringDetailFor(int id) => '/recurring-detail/$id';
}
