import 'package:flutter/material.dart';
import 'package:sistema_cuentas/core/theme/design_tokens.dart';
import 'package:sistema_cuentas/shared/widgets/app_metric_card.dart';

class KpiCardData {
  const KpiCardData({
    required this.title,
    required this.icon,
    required this.color,
    this.amount,
    this.text,
    this.hidden = false,
    this.onToggleHidden,
  }) : assert(amount != null || text != null, 'Pasa amount o text');

  final String title;
  final IconData icon;
  final Color color;

  /// Cifra numérica (en pesos): se anima y puede taparse.
  final double? amount;

  /// Alternativa: texto ya formateado, sin animación.
  final String? text;
  final bool hidden;

  /// Si se pasa, la tarjeta muestra el ojo para tapar/destapar la cifra.
  final VoidCallback? onToggleHidden;
}

/// Los indicadores del encabezado de una pantalla.
///
/// Si cada tarjeta cabe (ancho mínimo `kpiMinWidth`) van en **fila**; si no, se
/// **deslizan** en horizontal. Con [gridOnPhone] en un teléfono van en una
/// cuadrícula de dos, para pantallas donde los indicadores son lo principal.
/// Apilarlos en una columna está prohibido: en un teléfono tapa la lista.
class KpiCardsRow extends StatelessWidget {
  const KpiCardsRow({
    super.key,
    required this.cards,
    this.minCardWidth = DesignTokens.kpiMinWidth,
    this.gridOnPhone = false,
  });

  final List<KpiCardData> cards;
  final double minCardWidth;
  final bool gridOnPhone;

  static const double _gap = DesignTokens.spaceSm + DesignTokens.spaceXs;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final perCard = (width - _gap * (cards.length - 1)) / cards.length;
        if (perCard >= minCardWidth) return _InRow(cards: cards);
        final onPhone = width < DesignTokens.compactLayoutWidth;
        return gridOnPhone && onPhone
            ? _Grid(cards: cards, width: width)
            : _Slide(cards: cards);
      },
    );
  }
}

class _InRow extends StatelessWidget {
  const _InRow({required this.cards});

  final List<KpiCardData> cards;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, card) in cards.indexed) ...[
        if (index > 0) const SizedBox(width: KpiCardsRow._gap),
        Expanded(child: _Card(card: card)),
      ],
    ],
  );
}

class _Slide extends StatelessWidget {
  const _Slide({required this.cards});

  final List<KpiCardData> cards;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (index, card) in cards.indexed) ...[
          if (index > 0) const SizedBox(width: KpiCardsRow._gap),
          SizedBox(
            width: DesignTokens.kpiSlideWidth,
            child: _Card(card: card),
          ),
        ],
      ],
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid({required this.cards, required this.width});

  final List<KpiCardData> cards;
  final double width;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KpiCardsRow._gap,
    runSpacing: KpiCardsRow._gap,
    children: [
      for (final card in cards)
        SizedBox(
          width: (width - KpiCardsRow._gap) / 2,
          child: _Card(card: card, showIcon: false),
        ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.card, this.showIcon = true});

  final KpiCardData card;
  final bool showIcon;

  @override
  Widget build(BuildContext context) => AppMetricCard(
    title: card.title,
    amount: card.amount,
    text: card.text,
    icon: card.icon,
    color: card.color,
    hidden: card.hidden,
    onToggleHidden: card.onToggleHidden,
    showIcon: showIcon,
  );
}
