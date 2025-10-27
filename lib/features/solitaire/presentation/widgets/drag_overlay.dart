import 'package:flutter/material.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/card_view.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart'
    as game;

/// Widget pour afficher une carte en cours de drag au-dessus de tout
class DraggingCardOverlay extends StatelessWidget {
  const DraggingCardOverlay({
    required this.card,
    required this.position,
    required this.cardWidth,
    required this.cardHeight,
    super.key,
    this.scale = 1.1,
    this.opacity = 0.8,
  });

  final game.Card card;
  final Offset position;
  final double cardWidth;
  final double cardHeight;
  final double scale;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - (cardWidth * scale - cardWidth) / 2,
      top: position.dy - (cardHeight * scale - cardHeight) / 2,
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Material(
              color: Colors.transparent,
              child: CardView(
                card: card,
                width: cardWidth,
                height: cardHeight,
                elevation: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gestionnaire pour le système de drag avec overlay
class DragOverlayManager {
  DragOverlayManager(this.overlayState);
  OverlayEntry? _overlayEntry;
  final OverlayState overlayState;

  void startDrag(
    game.Card card,
    Offset position,
    double cardWidth,
    double cardHeight,
  ) {
    removeDrag();

    _overlayEntry = OverlayEntry(
      builder: (context) => DraggingCardOverlay(
        card: card,
        position: position,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  void updateDragPosition(Offset newPosition) {
    _overlayEntry?.markNeedsBuild();
  }

  void removeDrag() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  bool get isDragging => _overlayEntry != null;
}
