import 'package:flutter/material.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart'
    as game;
import 'package:solitaire_klondike/core/theme/app_theme.dart';

/// Widget pour afficher une carte de jeu
class CardView extends StatelessWidget {
  const CardView({
    required this.card,
    super.key,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
    this.size = CardSize.normal,
    this.elevation = 4.0,
    this.isDraggable = false,
    this.onDragStarted,
    this.onDragCompleted,
    this.onDragEnd,
    this.width,
    this.height,
  });

  final game.Card card;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final CardSize size;
  final double elevation;
  final bool isDraggable;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragCompleted;
  final VoidCallback? onDragEnd;

  /// Largeur forcée (priorité sur size)
  final double? width;

  /// Hauteur forcée (priorité sur size)
  final double? height;

  static const double aspectRatio =
      0.715; // Ratio largeur/hauteur d'une carte standard

  @override
  Widget build(BuildContext context) {
    final cardSize = width != null && height != null
        ? Size(width!, height!)
        : _getCardDimensions(size);

    final cardWidget = SizedBox(
      width: cardSize.width,
      height: cardSize.height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: CardPainter(
            card: card,
            isSelected: isSelected,
            isHighlighted: isHighlighted,
            gameColors: context.gameColors,
          ),
        ),
      ),
    );

    if (isDraggable && card.faceUp) {
      return Draggable<game.Card>(
        data: card,
        onDragStarted: onDragStarted,
        onDragCompleted: onDragCompleted,
        onDragEnd: (details) => onDragEnd?.call(),
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.1,
            child: Opacity(
              opacity: 0.8,
              child: cardWidget,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: cardWidget,
        ),
        child: IgnorePointer(
          ignoring: false, // Permet les interactions sur la carte
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: cardWidget,
          ),
        ),
      );
    } else {
      return IgnorePointer(
        ignoring:
            !isDraggable, // Les cartes non-draggables ignorent les événements
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: cardWidget,
        ),
      );
    }
  }

  Size _getCardDimensions(CardSize size) {
    switch (size) {
      case CardSize.small:
        return const Size(40, 56);
      case CardSize.normal:
        return const Size(60, 84);
      case CardSize.large:
        return const Size(80, 112);
    }
  }
}

/// Tailles disponibles pour les cartes
enum CardSize { small, normal, large }

/// Widget DragTarget pour les piles (tableau, fondations)
class PileDropTarget extends StatelessWidget {
  const PileDropTarget({
    required this.child,
    required this.onAccept,
    super.key,
    this.onWillAccept,
  });

  final Widget child;
  final void Function(game.Card) onAccept;
  final bool Function(game.Card?)? onWillAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<game.Card>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      onWillAcceptWithDetails: (details) =>
          onWillAccept?.call(details.data) ?? true,
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          decoration: isHovered
              ? BoxDecoration(
                  border: Border.all(
                    color: context.gameColors.selectedCardBorder,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: child,
        );
      },
    );
  }
}

/// Painter personnalisé pour dessiner les cartes
class CardPainter extends CustomPainter {
  const CardPainter({
    required this.card,
    required this.isSelected,
    required this.isHighlighted,
    required this.gameColors,
  });

  final game.Card card;
  final bool isSelected;
  final bool isHighlighted;
  final GameColors gameColors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    if (card.faceUp) {
      _drawFaceUpCard(canvas, size, rrect);
    } else {
      _drawFaceDownCard(canvas, size, rrect);
    }

    // Dessiner les bordures de sélection/surbrillance
    if (isSelected || isHighlighted) {
      _drawBorder(canvas, rrect);
    }
  }

  void _drawFaceUpCard(Canvas canvas, Size size, RRect rrect) {
    // Fond de la carte
    final cardPaint = Paint()
      ..color = gameColors.cardBackground
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, cardPaint);

    // Bordure de la carte
    final borderPaint = Paint()
      ..color = gameColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Couleur du symbole
    final suitColor = card.suit.color == game.CardColor.red
        ? gameColors.redSuit
        : gameColors.blackSuit;

    // Dessiner le rang et l'enseigne
    _drawRankAndSuit(canvas, size, suitColor);
  }

  void _drawFaceDownCard(Canvas canvas, Size size, RRect rrect) {
    // Fond de la carte (dos)
    final backPaint = Paint()
      ..color = gameColors.stockBackground
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, backPaint);

    // Bordure
    final borderPaint = Paint()
      ..color = gameColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Motif du dos de carte (simple croix)
    _drawCardBackPattern(canvas, size);
  }

  void _drawRankAndSuit(Canvas canvas, Size size, Color suitColor) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Dessiner le rang en haut à gauche
    textPainter.text = TextSpan(
      text: card.rank.symbol,
      style: TextStyle(
        color: suitColor,
        fontSize: size.width * 0.2,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.05));

    // Dessiner l'enseigne sous le rang
    textPainter.text = TextSpan(
      text: card.suit.symbol,
      style: TextStyle(
        color: suitColor,
        fontSize: size.width * 0.25,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.2));

    // Dessiner le rang en bas à droite (inversé)
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(3.14159); // 180 degrés

    textPainter.text = TextSpan(
      text: card.rank.symbol,
      style: TextStyle(
        color: suitColor,
        fontSize: size.width * 0.2,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.1, size.height * 0.05));

    canvas.restore();

    // Dessiner le symbole central pour les figures et les As
    _drawCentralSymbol(canvas, size, suitColor);
  }

  void _drawCentralSymbol(Canvas canvas, Size size, Color suitColor) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Pour simplifier, on dessine juste l'enseigne au centre
    final textPainter = TextPainter(
      text: TextSpan(
        text: card.suit.symbol,
        style: TextStyle(
          color: suitColor,
          fontSize: size.width * 0.4,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final textOffset = Offset(
      centerX - textPainter.width / 2,
      centerY - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  void _drawCardBackPattern(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gameColors.cardBackground.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Dessiner une croix simple
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final margin = size.width * 0.2;

    // Ligne horizontale
    canvas.drawLine(
      Offset(margin, centerY),
      Offset(size.width - margin, centerY),
      paint,
    );

    // Ligne verticale
    canvas.drawLine(
      Offset(centerX, margin),
      Offset(centerX, size.height - margin),
      paint,
    );
  }

  void _drawBorder(Canvas canvas, RRect rrect) {
    final borderPaint = Paint()
      ..color =
          isSelected ? gameColors.selectedCardBorder : gameColors.hintHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(CardPainter oldDelegate) {
    return oldDelegate.card != card ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isHighlighted != isHighlighted ||
        oldDelegate.gameColors != gameColors;
  }
}

/// Widget pour afficher une pile vide (emplacement)
class EmptyPileView extends StatelessWidget {
  const EmptyPileView({
    required this.type,
    super.key,
    this.onTap,
    this.size = CardSize.normal,
    this.child,
  });

  final String type; // 'foundation', 'tableau', 'stock', 'waste'
  final VoidCallback? onTap;
  final CardSize size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final cardSize = _getCardDimensions(size);
    final gameColors = context.gameColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardSize.width,
        height: cardSize.height,
        decoration: BoxDecoration(
          color: _getBackgroundColor(gameColors),
          border: Border.all(
            color: gameColors.cardBorder.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child ?? _buildDefaultContent(context),
      ),
    );
  }

  Size _getCardDimensions(CardSize size) {
    switch (size) {
      case CardSize.small:
        return const Size(40, 56);
      case CardSize.normal:
        return const Size(60, 84);
      case CardSize.large:
        return const Size(80, 112);
    }
  }

  Color _getBackgroundColor(GameColors gameColors) {
    switch (type) {
      case 'foundation':
        return gameColors.foundationBackground;
      case 'stock':
        return gameColors.stockBackground;
      case 'waste':
        return gameColors.wasteBackground;
      default:
        return gameColors.emptyPileBackground;
    }
  }

  Widget _buildDefaultContent(BuildContext context) {
    IconData? icon;
    switch (type) {
      case 'foundation':
        icon = Icons.home;
      case 'stock':
        icon = Icons.layers;
      case 'waste':
        icon = Icons.delete_outline;
      default:
        icon = Icons.add;
    }

    return Icon(
      icon,
      color: context.gameColors.cardBorder.withOpacity(0.5),
      size: 24,
    );
  }
}
