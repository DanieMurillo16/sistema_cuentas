/// Lo que el administrador manda para dar de alta a otra persona.
class UserDraft {
  const UserDraft({
    required this.fullName,
    required this.username,
    required this.password,
    required this.isAdmin,
  });

  final String fullName;
  final String username;
  final String password;
  final bool isAdmin;

  Map<String, dynamic> toJson() => {
    'nombre': fullName,
    'usuario': username,
    'clave': password,
    'rol': isAdmin ? 'ADMINISTRADOR' : 'USUARIO',
  };
}
