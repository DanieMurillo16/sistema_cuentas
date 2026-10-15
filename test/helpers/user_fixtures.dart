import 'package:sistema_cuentas/features/users/models/managed_user.dart';

/// `usuario` de `backend/docs/API.md`.
Map<String, dynamic> managedUserJson({
  int id = 7,
  String fullName = 'Daniel Murillo',
  String username = 'daniel',
  String role = 'USUARIO',
  bool active = true,
}) => {
  'id_usuario': id,
  'nombre_completo': fullName,
  'usuario': username,
  'rol': role,
  'activo': active,
};

ManagedUser buildManagedUser({
  int id = 7,
  String fullName = 'Daniel Murillo',
  String username = 'daniel',
  String role = 'USUARIO',
  bool active = true,
}) => ManagedUser(
  id: id,
  fullName: fullName,
  username: username,
  role: role,
  active: active,
);

/// Nombre de usuario largo (50 caracteres, el máximo del alta).
const longUsername = 'usuario.con.un.nombre.de.acceso.demasiado.largo.xx';
