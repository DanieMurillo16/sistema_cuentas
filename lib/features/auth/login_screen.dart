import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/auth/widgets/login_form.dart';
import 'package:sistema_cuentas/features/auth/widgets/login_header.dart';

/// Entrada a la app. Sin sesión el router siempre termina aquí; al iniciar
/// sesión el propio router lleva a Inicio.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          // El mínimo de alto centra el contenido; si no cabe (teclado, texto
          // grande) la pantalla se desplaza.
          builder: (context, constraints) => SingleChildScrollView(
            padding: DesignTokens.pagePadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - DesignTokens.spaceLg * 2,
              ),
              child: const Center(child: _LoginContent()),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: DesignTokens.loginMaxWidth),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LoginHeader(),
          SizedBox(height: DesignTokens.spaceXl),
          LoginForm(),
        ],
      ),
    );
  }
}
