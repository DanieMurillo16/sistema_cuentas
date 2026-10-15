import 'package:flutter/material.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message = 'Cargando…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}
