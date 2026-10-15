import 'package:flutter/material.dart';

/// Un mensaje de la pantalla de carga: un icono y lo que dice.
class SplashTip {
  const SplashTip(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Lo que se lee mientras la app carga, uno por vez.
const splashTips = <SplashTip>[
  SplashTip(
    Icons.account_balance_wallet_outlined,
    'Maneja tus gastos, ingresos y pagos, todo en un solo lugar.',
  ),
  SplashTip(
    Icons.event_repeat_rounded,
    'Lleva al día tus pagos recurrentes y sabe quién te debe.',
  ),
  SplashTip(
    Icons.bar_chart_rounded,
    'Mira por dónde entra y sale tu dinero cada mes.',
  ),
  SplashTip(
    Icons.sell_outlined,
    'Cada peso con su categoría y su medio de pago.',
  ),
];
