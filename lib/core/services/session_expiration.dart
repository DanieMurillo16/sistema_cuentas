import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionExpirationProvider = NotifierProvider<SessionExpiration, int>(
  SessionExpiration.new,
);
// La caducidad del catálogo nunca cierra la sesión administrativa.
final catalogExpirationProvider = NotifierProvider<SessionExpiration, int>(
  SessionExpiration.new,
);

class SessionExpiration extends Notifier<int> {
  @override
  int build() => 0;

  void notify() => state++;
}
