import 'package:sistema_cuentas/features/users/models/user_draft.dart';

/// Reglas puras del alta de usuarios (las mismas que valida el servidor).
abstract final class UserRules {
  static const nameMax = 100;
  static const usernameMin = 3;
  static const usernameMax = 50;
  static const passwordMin = 10;
  static const passwordMax = 72;

  static String? validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 2) return 'Escribe el nombre (mínimo 2 letras).';
    return null;
  }

  static String? validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.length < usernameMin) {
      return 'Mínimo $usernameMin caracteres.';
    }
    if (!RegExp(r'^[a-z0-9._-]+$').hasMatch(text)) {
      return 'Solo minúsculas, números, punto, guion y guion bajo.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < passwordMin) {
      return 'Mínimo $passwordMin caracteres.';
    }
    return null;
  }

  static UserDraft draft({
    required String name,
    required String username,
    required String password,
    required bool isAdmin,
  }) => UserDraft(
    fullName: name.trim(),
    username: username.trim(),
    password: password,
    isAdmin: isAdmin,
  );
}
