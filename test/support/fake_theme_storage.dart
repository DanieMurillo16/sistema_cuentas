import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/services/theme_storage.dart';

/// Guarda el tema en memoria y anota cada vez que se guarda.
class FakeThemeStorage implements ThemeStorage {
  FakeThemeStorage([this.stored = ThemeMode.system]);

  ThemeMode stored;
  final saved = <ThemeMode>[];

  @override
  Future<ThemeMode> read() async => stored;

  @override
  Future<void> save(ThemeMode mode) async {
    saved.add(mode);
    stored = mode;
  }
}
