import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/models/user_profile.dart';

/// Nombre de 40+ caracteres para probar que nada se desborda.
const longFullName =
    'María del Pilar Fernanda Rodríguez de la Hoz y Villamizar Peñaranda';

/// JSON de `perfil` como lo entrega `auth/login.php` y `auth/perfil.php`.
Map<String, dynamic> profileJson({
  int id = 7,
  String fullName = 'Daniel Murillo',
  String username = 'daniel',
  String role = 'USUARIO',
}) => {
  'id_usuario': id,
  'nombre_completo': fullName,
  'usuario': username,
  'rol': role,
};

/// `data` de la respuesta de login: `{perfil, permisos, token, expira_en}`.
Map<String, dynamic> loginDataJson({
  String token = 'token-abc',
  String fullName = 'Daniel Murillo',
  List<String> permissions = const ['movimientos.registrar'],
}) => {
  'perfil': profileJson(fullName: fullName),
  'permisos': permissions,
  'token': token,
  'expira_en': null,
};

/// Sobre uniforme de éxito del backend: `{success: true, data: ...}`.
Map<String, dynamic> successEnvelope(Object? data) => {
  'success': true,
  'data': data,
};

/// Sobre uniforme de error: `{success: false, codigo, error}`.
Map<String, dynamic> errorEnvelope(String code, String message) => {
  'success': false,
  'codigo': code,
  'error': message,
};

Session buildSession({
  int id = 7,
  String fullName = 'Daniel Murillo',
  String role = 'USUARIO',
  Set<String> permissions = const {'movimientos.registrar'},
}) => Session(
  user: UserProfile(id: id, fullName: fullName, username: 'daniel', role: role),
  permissions: permissions,
);
