/// Lo que la persona tiene hoy en un medio de pago (pesos completos).
class InitialBalanceEntry {
  const InitialBalanceEntry({required this.methodId, required this.pesos});

  final int methodId;
  final int pesos;
}
