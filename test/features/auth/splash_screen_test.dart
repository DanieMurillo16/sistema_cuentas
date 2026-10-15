import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/config/app_config.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/models/session.dart';
import 'package:sistema_cuentas/core/theme/app_colors.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/features/auth/data/auth_repository.dart';
import 'package:sistema_cuentas/features/auth/providers/splash_tip_provider.dart';
import 'package:sistema_cuentas/features/auth/splash_screen.dart';
import 'package:sistema_cuentas/features/auth/utils/splash_tips.dart';
import 'package:sistema_cuentas/features/auth/widgets/splash_content.dart';
import 'package:sistema_cuentas/features/auth/widgets/splash_tip_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_loader.dart';
import 'package:sistema_cuentas/shared/widgets/brand_logo.dart';

import '../../helpers/auth_fixtures.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/pump_at_sizes.dart';

const _offline = 'No fue posible conectar con el servidor. Revisa tu conexión.';

FakeAuthRepository _failing() => FakeAuthRepository(
  storedToken: true,
  onFetchSession: () async => throw const NetworkException(_offline),
);

FakeAuthRepository _loading() => FakeAuthRepository(
  storedToken: true,
  onFetchSession: () => Completer<Session>().future,
);

String get _first => splashTips[0].text;
String get _second => splashTips[1].text;
String get _third => splashTips[2].text;
String get _fourth => splashTips[3].text;

Future<void> _pump(
  WidgetTester tester,
  FakeAuthRepository repository, {
  bool noMotion = false,
  double textScale = 1,
  double width = 390,
  double height = 800,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: noMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const SplashScreen(),
      ),
    ),
  );
  await tester.pump();
}

/// Desmonta la pantalla: se cancela el temporizador del mensaje que rota (si
/// no, la prueba termina con un `Timer` pendiente).
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

/// Deja correr [seconds] y termina el fundido.
Future<void> _advance(WidgetTester tester, int seconds) async {
  await tester.pump(Duration(seconds: seconds));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('cargando', () {
    testWidgets(
      'nombre, primer mensaje y puntos; sin «Cargando…» ni progreso',
      (tester) async {
        await _pump(tester, _loading());

        expect(find.text(AppConfig.appName), findsOneWidget);
        expect(find.text('Cuentas Claras'), findsOneWidget);
        expect(find.byType(BrandLogo), findsOneWidget);
        expect(
          find.text(
            'Maneja tus gastos, ingresos y pagos, todo en un solo lugar.',
          ),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.text('Cargando…'), findsNothing);
        expect(find.text('Intentar nuevamente'), findsNothing);
        await _unmount(tester);
      },
    );

    testWidgets('no usa barra, círculo ni el cargador de página (AppLoader)', (
      tester,
    ) async {
      await _pump(tester, _loading());

      expect(find.byType(AppLoader), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await _unmount(tester);
    });

    testWidgets('los cuatro mensajes existen y el primero es el del contrato', (
      tester,
    ) async {
      expect(splashTips, hasLength(4));
      expect(
        splashTips.first.text,
        'Maneja tus gastos, ingresos y pagos, todo en un solo lugar.',
      );
      expect({for (final tip in splashTips) tip.text}, hasLength(4));
      expect({for (final tip in splashTips) tip.icon}, hasLength(4));
    });

    testWidgets('con alto de sobra el logo y el nombre quedan centrados', (
      tester,
    ) async {
      for (final height in [700.0, 900.0, 1200.0]) {
        await _pump(tester, _loading(), height: height);

        final logo = tester.getRect(find.byType(BrandLogo));
        final name = tester.getRect(find.text(AppConfig.appName));
        final centerY = (logo.top + name.bottom) / 2;
        expect(centerY, closeTo(height / 2, 2), reason: '$height');
        expect(logo.center.dx, closeTo(195, 1));
        await _unmount(tester);
      }
    });

    testWidgets('el logo y el nombre están sobre el centro de la pantalla', (
      tester,
    ) async {
      await _pump(tester, _loading(), height: 800);

      final brand = tester.getRect(find.byType(BrandLogo));
      final tips = tester.getRect(find.byType(SplashTipView));
      expect(brand.center.dx, closeTo(195, 1));
      expect(tips.top, greaterThan(brand.bottom), reason: 'mensajes debajo');
      await _unmount(tester);
    });
  });

  group('mensajes que rotan', () {
    testWidgets('cada 3 s cambia: 1 → 2 → 3 → 4 → 1', (tester) async {
      await _pump(tester, _loading());
      expect(find.text(_first), findsOneWidget);

      await _advance(tester, 3);
      expect(find.text(_second), findsOneWidget);
      expect(find.text(_first), findsNothing);

      await _advance(tester, 3);
      expect(find.text(_third), findsOneWidget);

      await _advance(tester, 3);
      expect(find.text(_fourth), findsOneWidget);

      await _advance(tester, 3);
      expect(find.text(_first), findsOneWidget, reason: 'vuelve al primero');
      await _unmount(tester);
    });

    testWidgets('antes de los 3 s sigue el primero', (tester) async {
      await _pump(tester, _loading());

      await tester.pump(const Duration(milliseconds: 2900));

      expect(find.text(_first), findsOneWidget);
      expect(find.text(_second), findsNothing);
      await _unmount(tester);
    });

    testWidgets('el cambio es con fundido: un instante conviven los dos', (
      tester,
    ) async {
      await _pump(tester, _loading());

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(_first), findsOneWidget);
      expect(find.text(_second), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(_first), findsNothing);
      expect(find.text(_second), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('cada mensaje se ve con su icono', (tester) async {
      await _pump(tester, _loading());

      for (var i = 0; i < splashTips.length; i++) {
        expect(find.byIcon(splashTips[i].icon), findsOneWidget, reason: '$i');
        await _advance(tester, 3);
      }
      await _unmount(tester);
    });

    testWidgets('cuatro puntos: el del mensaje actual es el ancho', (
      tester,
    ) async {
      await _pump(tester, _loading());
      List<double> widths() => [
        for (final dot in tester.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(SplashTipView),
            matching: find.byType(AnimatedContainer),
          ),
        ))
          dot.constraints!.maxWidth,
      ];

      expect(widths(), [
        DesignTokens.splashDotActiveWidth,
        DesignTokens.splashDotSize,
        DesignTokens.splashDotSize,
        DesignTokens.splashDotSize,
      ]);
      await _advance(tester, 3);
      await tester.pump(const Duration(milliseconds: 400));
      expect(widths(), [
        DesignTokens.splashDotSize,
        DesignTokens.splashDotActiveWidth,
        DesignTokens.splashDotSize,
        DesignTokens.splashDotSize,
      ]);
      await _unmount(tester);
    });

    testWidgets('colores de los puntos: acento el activo, borde de campos los '
        'demás', (tester) async {
      await _pump(tester, _loading());

      final colors = [
        for (final dot in tester.widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(SplashTipView),
            matching: find.byType(AnimatedContainer),
          ),
        ))
          (dot.decoration! as BoxDecoration).color,
      ];
      expect(colors, [
        AppColors.accent,
        AppColors.inputBorder,
        AppColors.inputBorder,
        AppColors.inputBorder,
      ]);
      await _unmount(tester);
    });

    testWidgets('el bloque reserva el alto mínimo y no salta entre mensajes', (
      tester,
    ) async {
      await _pump(tester, _loading());
      final heights = <double>[];
      final logoTops = <double>[];
      for (var i = 0; i < splashTips.length; i++) {
        heights.add(tester.getSize(find.byType(SplashTipView)).height);
        logoTops.add(tester.getTopLeft(find.byType(BrandLogo)).dy);
        await _advance(tester, 3);
      }

      expect(heights.toSet(), hasLength(1), reason: '$heights');
      expect(
        heights.first,
        greaterThanOrEqualTo(DesignTokens.splashTipMinHeight),
      );
      expect(logoTops.toSet(), hasLength(1), reason: 'el logo no se mueve');
      await _unmount(tester);
    });

    testWidgets('al desmontar la pantalla se cancela el temporizador', (
      tester,
    ) async {
      await _pump(tester, _loading());
      final container = _container(tester);
      expect(container.exists(splashTipIndexProvider), isTrue);

      await _unmount(tester);

      // El framework falla si queda un Timer pendiente; además se avanza.
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    });

    testWidgets('el índice recorre 1, 2, 3, 0, 1 (módulo de los mensajes)', (
      tester,
    ) async {
      await _pump(tester, _loading());
      final container = _container(tester);
      final seen = <int>[];
      container.listen(splashTipIndexProvider, (_, next) {
        if (next.hasValue) seen.add(next.requireValue);
      });

      for (var i = 0; i < 5; i++) {
        await _advance(tester, 3);
      }

      expect(seen, [1, 2, 3, 0, 1]);
      await _unmount(tester);
    });
  });

  group('«reducir movimiento»', () {
    testWidgets('muestra siempre el primer mensaje, pasen los segundos que '
        'pasen', (tester) async {
      await _pump(tester, _loading(), noMotion: true);

      await _advance(tester, 3);
      await _advance(tester, 3);
      await _advance(tester, 9);

      expect(find.text(_first), findsOneWidget);
      expect(find.text(_second), findsNothing);
      await _unmount(tester);
    });

    testWidgets('ni siquiera escucha el temporizador (el índice no avanza)', (
      tester,
    ) async {
      await _pump(tester, _loading(), noMotion: true);

      expect(
        _container(tester).exists(splashTipIndexProvider),
        isFalse,
        reason: 'el provider no se lee',
      );
      await _unmount(tester);
    });

    testWidgets('el primer punto queda activo', (tester) async {
      await _pump(tester, _loading(), noMotion: true);
      await _advance(tester, 6);

      final dots = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(SplashTipView),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(
        dots.first.constraints!.maxWidth,
        DesignTokens.splashDotActiveWidth,
      );
      await _unmount(tester);
    });
  });

  group('semántica', () {
    testWidgets('una sola región viva «Cargando»; los mensajes no se leen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _loading());

      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
      final node = tester.getSemantics(find.bySemanticsLabel('Cargando'));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      // Ni la barra, ni «Cargando…», ni los mensajes ni sus puntos por separado.
      expect(find.bySemanticsLabel(RegExp('Cargando…')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Maneja tus gastos')), findsNothing);
      for (final tip in splashTips) {
        expect(find.bySemanticsLabel(tip.text), findsNothing);
      }
      await _advance(tester, 3);
      expect(find.bySemanticsLabel(RegExp('Lleva al día')), findsNothing);
      await _unmount(tester);
      handle.dispose();
    });
  });

  group('error de sesión', () {
    testWidgets('mensaje en español y «Intentar nuevamente»; sin mensajes ni '
        'progreso', (tester) async {
      await _pump(tester, _failing());
      await tester.pumpAndSettle();

      expect(find.text(_offline), findsOneWidget);
      expect(find.text('Intentar nuevamente'), findsOneWidget);
      expect(find.byType(SplashContent), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Cargando…'), findsNothing);
      for (final tip in splashTips) {
        expect(find.text(tip.text), findsNothing);
      }
      await _unmount(tester);
    });

    testWidgets('«Intentar nuevamente» vuelve a pedir la sesión', (
      tester,
    ) async {
      final repository = _failing();
      await _pump(tester, repository);
      await tester.pumpAndSettle();
      expect(repository.fetchSessionCalls, 1);

      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(repository.fetchSessionCalls, 2);
      await _unmount(tester);
    });

    testWidgets('mientras reintenta se ve la carga, no el error anterior', (
      tester,
    ) async {
      var attempt = 0;
      final retry = Completer<Session>();
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () {
          attempt++;
          if (attempt == 1) throw const NetworkException(_offline);
          return retry.future;
        },
      );
      await _pump(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text(_offline), findsOneWidget);

      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pump();

      // Ya está pidiendo otra vez: se ve la carga con sus mensajes.
      expect(find.text(_offline), findsNothing);
      expect(find.text('Intentar nuevamente'), findsNothing);
      expect(find.byType(SplashContent), findsOneWidget);
      expect(find.text(_first), findsOneWidget);
      await _unmount(tester);
    });

    testWidgets('si el reintento también falla vuelve el error', (
      tester,
    ) async {
      final repository = _failing();
      await _pump(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pumpAndSettle();

      expect(find.text(_offline), findsOneWidget);
      expect(find.byType(SplashContent), findsNothing);
      await _unmount(tester);
    });

    testWidgets('si el reintento sale bien, la pantalla deja de pedirse '
        'error', (tester) async {
      var attempt = 0;
      final repository = FakeAuthRepository(
        storedToken: true,
        onFetchSession: () async {
          attempt++;
          if (attempt == 1) throw const NetworkException(_offline);
          return buildSession();
        },
      );
      await _pump(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Intentar nuevamente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(_offline), findsNothing);
      await _unmount(tester);
    });
  });

  group('sin desbordes', () {
    testWidgets('cargando, matriz 320/390/800/1300 × teclado × texto 1.5', (
      tester,
    ) async {
      await expectNoOverflow(
        tester,
        const SplashScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(_loading())],
        settle: false,
      );
      await _unmount(tester);
    });

    testWidgets('cargando con «reducir movimiento»', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final width in testWidths) {
        for (final scale in testTextScales) {
          tester.view.physicalSize = Size(width, 700);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [authRepositoryProvider.overrideWithValue(_loading())],
              child: MaterialApp(
                theme: AppTheme.dark,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: const SplashScreen(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.takeException(),
            isNull,
            reason: '$width px · texto $scale',
          );
        }
      }
      await _unmount(tester);
    });

    testWidgets('con cada uno de los cuatro mensajes (cambian de tamaño)', (
      tester,
    ) async {
      for (final scale in testTextScales) {
        for (final width in testWidths) {
          await _pump(
            tester,
            _loading(),
            width: width,
            height: 700,
            textScale: scale,
          );
          for (var i = 0; i < splashTips.length; i++) {
            expect(
              tester.takeException(),
              isNull,
              reason: '$width px · texto $scale · mensaje $i',
            );
            await _advance(tester, 3);
          }
          await _unmount(tester);
        }
      }
    });

    testWidgets('error y botón de reintento, matriz completa', (tester) async {
      await expectNoOverflow(
        tester,
        const SplashScreen(),
        overrides: [authRepositoryProvider.overrideWithValue(_failing())],
        retry: (_, _) => null,
      );
    });
  });

  group('poca altura: se desplaza en vez de desbordar', () {
    const cases = {
      'teléfono muy bajo 320×300': (320.0, 300.0),
      'apaisado 568×320': (568.0, 320.0),
      'bajo 360': (390.0, 360.0),
      'iPhone SE 320×568': (320.0, 568.0),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key}: sin desbordes, con texto 1.0 y 1.5', (
        tester,
      ) async {
        final (width, height) = entry.value;
        for (final scale in testTextScales) {
          await _pump(
            tester,
            _loading(),
            width: width,
            height: height,
            textScale: scale,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$width×$height · texto $scale',
          );
          await _unmount(tester);
        }
      });
    }

    testWidgets(
      '320×300: hay scroll y al final se alcanzan los puntos de los mensajes',
      (tester) async {
        await _pump(tester, _loading(), width: 320, height: 300);

        final scrollView = find.descendant(
          of: find.byType(SplashContent),
          matching: find.byType(SingleChildScrollView),
        );
        expect(scrollView, findsOneWidget);
        // El contenido no cabe en 300: el alto sale de lo que hay que mostrar.
        final position = tester
            .state<ScrollableState>(
              find.descendant(
                of: scrollView,
                matching: find.byType(Scrollable),
              ),
            )
            .position;
        expect(position.maxScrollExtent, greaterThan(0));
        expect(
          position.viewportDimension + position.maxScrollExtent,
          greaterThan(300),
        );

        await tester.drag(scrollView, const Offset(0, -1000));
        await tester.pump();
        final tips = tester.getRect(find.byType(SplashTipView));
        expect(tips.bottom, lessThanOrEqualTo(300));
        expect(tips.top, greaterThanOrEqualTo(-300));
        await _unmount(tester);
      },
    );

    testWidgets('con alto de sobra no hay scroll (cabe todo)', (tester) async {
      await _pump(tester, _loading(), width: 390, height: 900);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.maxScrollExtent, 0);
      await _unmount(tester);
    });
  });
}
