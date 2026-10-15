/// Todas las rutas de la API como constantes (espejo de `backend/docs/API.md`).
/// Cero URLs literales en repositorios o servicios: cada feature usa las suyas.
abstract final class ApiEndpoints {
  // Sesión
  static const login = 'auth/login.php';
  static const profile = 'auth/perfil.php';
  static const logout = 'auth/logout.php';

  // Usuarios (solo administrador)
  static const usersList = 'usuarios/listar.php';
  static const userCreate = 'usuarios/crear.php';
  static const userSetStatus = 'usuarios/estado.php';

  // Catálogos
  static const categories = 'catalogos/categorias.php';
  static const categorySave = 'catalogos/categoria_guardar.php';
  static const categoryDelete = 'catalogos/categoria_eliminar.php';
  static const paymentMethods = 'catalogos/medios.php';
  static const paymentMethodSave = 'catalogos/medio_guardar.php';
  static const contacts = 'catalogos/contactos.php';
  static const contactSave = 'catalogos/contacto_guardar.php';

  // Pagos recurrentes
  static const recurringList = 'pagos_recurrentes/listar.php';
  static const recurringDetail = 'pagos_recurrentes/detalle.php';
  static const recurringCreate = 'pagos_recurrentes/crear.php';
  static const recurringEdit = 'pagos_recurrentes/editar.php';
  static const recurringFinish = 'pagos_recurrentes/finalizar.php';
  static const recurringDelete = 'pagos_recurrentes/eliminar.php';
  static const accountReset = 'cuenta/reiniciar_datos.php';

  // Vencimientos
  static const duesList = 'vencimientos/listar.php';
  static const duesAgenda = 'vencimientos/agenda.php';
  static const dueAdjust = 'vencimientos/ajustar.php';
  static const dueCancel = 'vencimientos/anular.php';

  // Movimientos
  static const movementsList = 'movimientos/listar.php';
  static const movementRegister = 'movimientos/registrar.php';
  static const movementUpdate = 'movimientos/actualizar.php';
  static const movementCancel = 'movimientos/anular.php';

  // Resumen
  static const summaryMonth = 'resumen/mes.php';
  static const summaryRange = 'resumen/rango.php';
}
