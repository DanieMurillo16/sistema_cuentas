import 'package:sistema_cuentas/core/models/movement_type.dart';
import 'package:sistema_cuentas/features/summary/models/category_total.dart';
import 'package:sistema_cuentas/core/utils/date_formatter.dart';
import 'package:sistema_cuentas/features/summary/models/method_total.dart';
import 'package:sistema_cuentas/features/summary/models/monthly_point.dart';

/// Lo que entró y salió por un medio de pago en el mes.
class MethodFlow {
  const MethodFlow({
    required this.methodId,
    required this.name,
    required this.incomeCents,
    required this.expenseCents,
  });

  final int methodId;
  final String name;
  final int incomeCents;
  final int expenseCents;

  /// Lo que quedó en ese medio este mes: entró menos salió.
  int get netCents => incomeCents - expenseCents;
}

/// Una categoría con su parte del total de su grupo (para la barra).
class CategoryShare {
  const CategoryShare({
    required this.name,
    required this.totalCents,
    required this.count,
    required this.share,
    this.categoryId,
  });

  /// `null` en «Otras» (varias categorías juntas).
  final int? categoryId;
  final String name;
  final int totalCents;
  final int count;

  /// De 0 a 1: qué parte del total del grupo es esta categoría.
  final double share;
}

/// Reglas puras del resumen (sin Flutter). Solo reorganizan las filas que ya
/// calculó el servidor: no inventan cifras.
abstract final class SummaryRules {
  /// Une las filas de ingreso y gasto de cada medio y las ordena: primero el
  /// que más dejó este mes.
  static List<MethodFlow> methodFlows(List<MethodTotal> rows) {
    final byMethod = <int, MethodFlow>{};
    for (final row in rows) {
      final current = byMethod[row.methodId];
      final income =
          (current?.incomeCents ?? 0) +
          (row.type.isIncome ? row.totalCents : 0);
      final expense =
          (current?.expenseCents ?? 0) +
          (row.type.isIncome ? 0 : row.totalCents);
      byMethod[row.methodId] = MethodFlow(
        methodId: row.methodId,
        name: row.name,
        incomeCents: income,
        expenseCents: expense,
      );
    }
    return byMethod.values.toList()..sort((a, b) {
      final byNet = b.netCents.compareTo(a.netCents);
      return byNet != 0 ? byNet : a.name.compareTo(b.name);
    });
  }

  /// Lo que entró (o salió) por cada medio, de mayor a menor. Los medios sin
  /// movimientos de ese tipo no salen.
  static List<MethodTotal> methodsOf(
    List<MethodTotal> rows,
    MovementType type,
  ) {
    return rows.where((r) => r.type == type && r.totalCents > 0).toList()
      ..sort((a, b) {
        final byTotal = b.totalCents.compareTo(a.totalCents);
        return byTotal != 0 ? byTotal : a.name.compareTo(b.name);
      });
  }

  /// Las categorías de un tipo (sin las de capital, que se muestran aparte),
  /// de la que más suma a la que menos, con su parte del total.
  static List<CategoryShare> categoryShares(
    List<CategoryTotal> rows,
    MovementType type,
  ) {
    final group = [
      for (final row in rows)
        if (row.type == type && !row.isCapital) row,
    ]..sort((a, b) => b.totalCents.compareTo(a.totalCents));
    final total = group.fold<int>(0, (sum, row) => sum + row.totalCents);
    return [
      for (final row in group)
        CategoryShare(
          categoryId: row.categoryId,
          name: row.name,
          totalCents: row.totalCents,
          count: row.count,
          share: total <= 0 ? 0 : row.totalCents / total,
        ),
    ];
  }

  /// Suma de un grupo de categorías (para su encabezado).
  static int groupTotal(List<CategoryShare> shares) =>
      shares.fold<int>(0, (sum, share) => sum + share.totalCents);

  /// Las [max] categorías que más suman; el resto se junta en «Otras» para que
  /// la dona se lea de un vistazo.
  static List<CategoryShare> topCategories(
    List<CategoryShare> shares, {
    int max = 6,
  }) {
    if (shares.length <= max) return shares;
    final top = shares.take(max - 1).toList();
    final rest = shares.skip(max - 1).toList();
    final restTotal = groupTotal(rest);
    final total = groupTotal(shares);
    return [
      ...top,
      CategoryShare(
        name: 'Otras',
        totalCents: restTotal,
        count: rest.fold<int>(0, (sum, s) => sum + s.count),
        share: total <= 0 ? 0 : restTotal / total,
      ),
    ];
  }

  /// Variación en % de [current] frente a [previous]; `null` si antes era cero
  /// (no hay con qué comparar).
  static int? deltaPercent(int current, int previous) {
    if (previous <= 0) return null;
    return (((current - previous) / previous) * 100).round();
  }

  /// Por cada medio de un tipo: lo de este mes y lo del mes pasado, de mayor a
  /// menor este mes (así se ve por dónde entra, o sale, más dinero).
  static List<MethodComparison> methodComparison({
    required List<MethodTotal> current,
    required List<MethodTotal> previous,
    required MovementType type,
  }) {
    final byId = <int, ({String name, int current, int previous})>{};
    for (final row in current) {
      if (row.type != type) continue;
      byId[row.methodId] = (
        name: row.name,
        current: row.totalCents,
        previous: 0,
      );
    }
    for (final row in previous) {
      if (row.type != type) continue;
      final seen = byId[row.methodId];
      byId[row.methodId] = (
        name: seen?.name ?? row.name,
        current: seen?.current ?? 0,
        previous: row.totalCents,
      );
    }
    return [
      for (final entry in byId.entries)
        MethodComparison(
          methodId: entry.key,
          name: entry.value.name,
          currentCents: entry.value.current,
          previousCents: entry.value.previous,
        ),
    ]..sort((a, b) {
      final byCurrent = b.currentCents.compareTo(a.currentCents);
      return byCurrent != 0
          ? byCurrent
          : b.previousCents.compareTo(a.previousCents);
    });
  }

  /// Una barra doble (ingresos y gastos) por mes de la serie.
  static List<MonthBar> trendBars(List<MonthlyPoint> points) => [
    for (final point in points)
      MonthBar(
        month: point.month,
        label: formatMonthShort(point.month),
        incomeCents: point.summary.totals.incomeTotalCents,
        expenseCents: point.summary.totals.expenseTotalCents,
      ),
  ];
}

/// Los ingresos y gastos de un mes, listos para dibujar sus barras.
class MonthBar {
  const MonthBar({
    required this.month,
    required this.label,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime month;
  final String label;
  final int incomeCents;
  final int expenseCents;
}

/// Lo que entró (o salió) por un medio este mes frente al mes pasado.
class MethodComparison {
  const MethodComparison({
    required this.methodId,
    required this.name,
    required this.currentCents,
    required this.previousCents,
  });

  final int methodId;
  final String name;
  final int currentCents;
  final int previousCents;

  int? get deltaPercent =>
      SummaryRules.deltaPercent(currentCents, previousCents);
}
