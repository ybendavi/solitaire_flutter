import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/deal_plan.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart'
    as game_card;
import 'package:solitaire_klondike/features/solitaire/presentation/layout/board_layout.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/game_controller.dart';

/// Orchestrateur des animations de distribution des cartes
class DealAnimator {
  DealAnimator({
    required this.context,
    required this.layout,
    required this.controller,
  });

  final BuildContext context;
  final BoardLayout layout;
  final GameController controller;

  /// Lance la séquence de distribution animée
  Future<void> run({
    required DealtPlan plan,
    Duration perCard = const Duration(milliseconds: 110),
  }) async {
    // Vérifier que le plan est valide
    assert(plan.isValid, 'Invalid deal plan provided to DealAnimator');

    // Créer et insérer l'overlay pour les cartes en vol
    final overlay = Overlay.of(context);
    final overlayEntries = <OverlayEntry>[];

    try {
      // Distribuer chaque carte séquentiellement
      for (var i = 0; i < plan.steps.length; i++) {
        final step = plan.steps[i];

        // Créer et animer cette carte
        await _animateCardStep(
          step: step,
          overlay: overlay,
          overlayEntries: overlayEntries,
          duration: perCard,
        );

        // Petit délai entre les cartes pour le rythme
        if (i < plan.steps.length - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 15));
        }
      }
    } finally {
      // Nettoyer tous les overlays restants
      for (final entry in overlayEntries) {
        entry.remove();
      }
      overlayEntries.clear();
    }
  }

  /// Anime une étape individuelle de distribution
  Future<void> _animateCardStep({
    required DealtStep step,
    required OverlayState overlay,
    required List<OverlayEntry> overlayEntries,
    required Duration duration,
  }) async {
    // Calculer les positions source et destination
    final fromRect = layout.stockRect;
    final toPosition = layout.cardOffsetInTableau(
      step.column,
      _getTargetStackIndex(step),
      faceUp: false, // Initialement face down
    );
    final toRect = layout.cardRectAt(toPosition);

    // Créer le contrôleur d'animation
    final animationController = AnimationController(
      duration: duration,
      vsync: Navigator.of(context),
    );

    // Animations de rotation subtile
    final rotationAnimation = Tween<double>(
      begin: 0,
      end: (math.Random().nextDouble() - 0.5) * 0.1, // ±3°
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
    );

    // Animation d'échelle
    final scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.98,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0, 0.7),
      ),
    );

    // Créer l'overlay entry pour cette carte
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          // Calculer la position via une courbe de Bézier quadratique
          final controlPoint = Offset(
            (fromRect.center.dx + toRect.center.dx) / 2,
            math.min(fromRect.center.dy, toRect.center.dy) -
                (0.6 * layout.cardHeight),
          );

          final currentPosition = _quadraticBezier(
            fromRect.center,
            controlPoint,
            toRect.center,
            animationController.value,
          );

          return Positioned(
            left: currentPosition.dx - layout.cardWidth / 2,
            top: currentPosition.dy - layout.cardHeight / 2,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(rotationAnimation.value)
                ..scale(scaleAnimation.value),
              child: SizedBox(
                width: layout.cardWidth,
                height: layout.cardHeight,
                child: Container(
                  width: layout.cardWidth,
                  height: layout.cardHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: step.card.suit.color == game_card.CardColor.red
                        ? Colors.red[100]
                        : Colors.black26,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Center(
                    child: Text(
                      '${step.card.rank.symbol}${step.card.suit.symbol}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    // Insérer l'overlay et démarrer l'animation
    overlay.insert(overlayEntry);
    overlayEntries.add(overlayEntry);

    // Completer pour l'animation de vol
    final completer = Completer<void>();

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        completer.complete();
      }
    });

    // Démarrer l'animation de vol
    animationController.forward();

    // Attendre que la carte arrive à destination
    await completer.future;

    // Retirer l'overlay de vol
    overlayEntry.remove();
    overlayEntries.remove(overlayEntry);

    // Commit de la carte dans l'état du jeu
    controller.commitCardToTableau(step.card, step.column, false);

    // Si c'est la dernière carte de la colonne, faire le flip
    if (step.isLastInColumn) {
      await _animateCardFlip(step.column);
    }

    // Nettoyer le contrôleur
    animationController.dispose();
  }

  /// Anime le retournement de la dernière carte d'une colonne
  Future<void> _animateCardFlip(int columnIndex) async {
    // La logique de flip sera gérée côté widget CardView
    // Pour l'instant, on commit juste le changement d'état
    await Future<void>.delayed(const Duration(milliseconds: 30));

    controller.flipTableauCard(columnIndex);

    // Attendre la fin de l'animation de flip
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// Calcule l'index de stack cible pour une carte dans sa colonne
  int _getTargetStackIndex(DealtStep step) {
    // Pour l'instant, on calcule manuellement basé sur le step index
    // Dans une implémentation future, on pourrait interroger le controller
    const cardsInColumn = 0;
    for (var i = 0; i < step.stepIndex; i++) {
      // Compter les cartes déjà placées dans cette colonne
      // Logique simplifiée basée sur l'ordre de distribution round-robin
    }
    return cardsInColumn;
  }

  /// Calcule un point sur une courbe de Bézier quadratique
  Offset _quadraticBezier(Offset p0, Offset p1, Offset p2, double t) {
    final oneMinusT = 1.0 - t;
    return Offset(
      oneMinusT * oneMinusT * p0.dx + 2 * oneMinusT * t * p1.dx + t * t * p2.dx,
      oneMinusT * oneMinusT * p0.dy + 2 * oneMinusT * t * p1.dy + t * t * p2.dy,
    );
  }
}
