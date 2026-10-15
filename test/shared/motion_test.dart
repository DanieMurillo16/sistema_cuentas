import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/shared/widgets/animated_number_text.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';

/// Cada consulta del provider queda pendiente hasta que el test la complete.
final _requests = <Completer<List<int>>>[];

final _itemsProvider = AsyncNotifierProvider<_Items, List<int>>(_Items.new);

class _Items extends AsyncNotifier<List<int>> {
  @override
  Future<List<int>> build() {
    final request = Completer<List<int>>();
    _requests.add(request);
    return request.future;
  }
}

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: child),
);

AppAsyncView<List<int>> _view(AsyncValue<List<int>> state) =>
    AppAsyncView<List<int>>(
      state: state,
      isEmpty: (items) => items.isEmpty,
      onRetry: () {},
      builder: (items) => Text('datos: ${items.length}'),
    );

void main() {
  testWidgets('AppAsyncView resuelve datos, cargando, error y vacío', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_view(const AsyncLoading())));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(_host(_view(const AsyncData([1, 2]))));
    await tester.pumpAndSettle();
    expect(find.text('datos: 2'), findsOneWidget);

    await tester.pumpWidget(_host(_view(const AsyncData([]))));
    await tester.pumpAndSettle();
    expect(find.text('Sin registros'), findsOneWidget);

    await tester.pumpWidget(
      _host(_view(AsyncError(Exception('x'), StackTrace.empty))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Intentar nuevamente'), findsOneWidget);
  });

  testWidgets('ref.invalidate con datos NO vacía la pantalla', (tester) async {
    _requests.clear();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => _view(ref.watch(_itemsProvider)),
            ),
          ),
        ),
      ),
    );
    _requests[0].complete([1, 2]);
    await tester.pumpAndSettle();
    expect(find.text('datos: 2'), findsOneWidget);

    // Una edición o un borrado invalidan el provider y se vuelve a consultar.
    ProviderScope.containerOf(tester.element(find.byType(Consumer)))
        .invalidate(_itemsProvider);
    await tester.pump();
    expect(find.text('datos: 2'), findsOneWidget, reason: 'los datos siguen');
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Llegan los datos nuevos: se actualizan en su lugar y se va la barra.
    _requests[1].complete([1, 2, 3]);
    await tester.pumpAndSettle();
    expect(find.text('datos: 3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('AnimatedNumberText cuenta, se desliza y se tapa', (
    tester,
  ) async {
    Widget number(double value, {bool obscured = false}) =>
        _host(AnimatedNumberText(value: value, obscured: obscured));

    await tester.pumpWidget(number(1000));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(r'$ 1.000'), findsNothing, reason: 'aún está contando');
    await tester.pumpAndSettle();
    expect(find.text(r'$ 1.000'), findsOneWidget);

    await tester.pumpWidget(number(2000));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(r'$ 2.000'), findsNothing, reason: 'se desliza al nuevo');
    await tester.pumpAndSettle();
    expect(find.text(r'$ 2.000'), findsOneWidget);

    await tester.pumpWidget(number(2000, obscured: true));
    expect(find.text(AnimatedNumberText.mask), findsOneWidget);
  });

  testWidgets('con "reducir movimiento" los cambios son inmediatos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(body: AnimatedNumberText(value: 500)),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(r'$ 500'), findsOneWidget);
  });
}
