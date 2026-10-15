/// Validación de los campos del login (reglas puras, sin Flutter).
abstract final class AuthRules {
  static const usernameMaxLength = 50;
  static const passwordMaxLength = 72;

  static String? validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Escribe tu usuario.';
    if (text.length < 3) return 'El usuario tiene al menos 3 caracteres.';
    return null;
  }

  static String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Escribe tu contraseña.';
    return null;
  }
}
