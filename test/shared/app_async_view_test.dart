import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_cuentas/core/errors/app_exception.dart';
import 'package:sistema_cuentas/core/theme/app_theme.dart';
import 'package:sistema_cuentas/core/utils/async_utils.dart';
import 'package:sistema_cuentas/shared/widgets/app_async_view.dart';
import 'package:sistema_cuentas/shared/widgets/app_error_view.dart';
import 'package:sistema_cuentas/shared/widgets/refresh_failed_banner.dart';

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

var _retries = 0;

Widget _app({required Widget child}) => ProviderScope(
  retry: (_, _) => null,
  child: MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  ),
);

Widget _watching() => Consumer(
  builder: (context, ref, _) => AppAsyncView<List<int>>(
    state: ref.watch(_itemsProvider),
    isEmpty: (items) => items.isEmpty,
    onRetry: () {
      _retries++;
      ref.invalidate(_itemsProvider);
    },
    builder: (items) => Text('datos: ${items.length}'),
  ),
);

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Consumer)));

void main() {
  setUp(() {
    _requests.clear();
    _retries = 0;
  });

  testWidgets('sin datos, un error ocupa la página con «Intentar nuevamente»', (
    tester,
  ) async {
    await tester.pumpWidget(_app(child: _watching()));
    _requests[0].completeError(const NetworkException('Sin conexión.'));
    await tester.pumpAndSettle();

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.text('Sin conexión.'), findsOneWidget);
    expect(find.text('Intentar nuevamente'), findsOneWidget);
    expect(find.byType(RefreshFailedBanner), findsNothing);
  });

  testWidgets(
    'un refresco que falla CONSERVA los datos y avisa con un banner «Reintentar»',
    (tester) async {
      await tester.pumpWidget(_app(child: _watching()));
      _requests[0].complete([1, 2]);
      await tester.pumpAndSettle();
      expect(find.text('datos: 2'), findsOneWidget);

      _container(tester).invalidate(_itemsProvider);
      await tester.pump();
      _requests[1].completeError(const NetworkException('Sin conexión.'));
      await tester.pumpAndSettle();

      expect(find.text('datos: 2'), findsOneWidget, reason: 'los datos siguen');
      expect(find.byType(RefreshFailedBanner), findsOneWidget);
      expect(find.text('Sin conexión.'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('«Reintentar» vuelve a pedir; al llegar se va el banner', (
    tester,
  ) async {
    await tester.pumpWidget(_app(child: _watching()));
    _requests[0].complete([1, 2]);
    await tester.pumpAndSettle();
    _container(tester).invalidate(_itemsProvider);
    await tester.pump();
    _requests[1].completeError(const NetworkException('Sin conexión.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reintentar'));
    await tester.pump();

    expect(_retries, 1);
    expect(_requests, hasLength(3));
    expect(find.text('datos: 2'), findsOneWidget, reason: 'sigue en pantalla');
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    _requests[2].complete([1, 2, 3]);
    await tester.pumpAndSettle();
    expect(find.text('datos: 3'), findsOneWidget);
    expect(find.byType(RefreshFailedBanner), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets(
    'un banner con un mensaje largo no desborda (320 px, texto 1.5)',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
              textScaler: TextScaler.linear(1.5),
            ),
            child: RefreshFailedBanner(
              message: 'Sin conexión con el servidor. ' * 6,
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  group('mapKeepingData', () {
    test('con datos los transforma', () {
      final result = mapKeepingData<List<int>, int>(
        const AsyncData([1, 2, 3]),
        (items) => items.length,
      );
      expect(result.value, 3);
    });

    test('cargando sin datos sigue cargando', () {
      final result = mapKeepingData<List<int>, int>(
        const AsyncLoading(),
        (items) => items.length,
      );
      expect(result.isLoading, isTrue);
      expect(result.hasValue, isFalse);
    });

    test('error sin datos sigue siendo error', () {
      final result = mapKeepingData<List<int>, int>(
        AsyncError(const NetworkException('x'), StackTrace.empty),
        (items) => items.length,
      );
      expect(result.hasError, isTrue);
      expect(result.hasValue, isFalse);
    });

    test('recargando con datos conserva y transforma el último dato', () async {
      final container = ProviderContainer(retry: (_, _) => null);
      addTearDown(container.dispose);
      container.listen(_itemsProvider, (_, _) {});
      _requests[0].complete([1, 2]);
      await container.read(_itemsProvider.future);

      container.invalidate(_itemsProvider);
      await Future<void>.delayed(Duration.zero);

      final reloading = container.read(_itemsProvider);
      expect(reloading.isLoading, isTrue);
      final result = mapKeepingData<List<int>, int>(
        reloading,
        (items) => items.length,
      );
      expect(result.value, 2);
    });

    test('refresco fallido con datos previos los conserva', () async {
      final container = ProviderContainer(retry: (_, _) => null);
      addTearDown(container.dispose);
      container.listen(_itemsProvider, (_, _) {});
      _requests[0].complete([1, 2, 3]);
      await container.read(_itemsProvider.future);

      container.invalidate(_itemsProvider);
      await Future<void>.delayed(Duration.zero);
      _requests[1].completeError(const NetworkException('x'));
      await expectLater(
        container.read(_itemsProvider.future),
        throwsA(isA<NetworkException>()),
      );

      final failed = container.read(_itemsProvider);
      expect(failed.hasError, isTrue);
      final result = mapKeepingData<List<int>, int>(
        failed,
        (items) => items.length,
      );
      expect(result.value, 3);
    });
  });
}
