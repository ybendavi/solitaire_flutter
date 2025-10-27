import 'package:equatable/equatable.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';

/// Une étape de distribution représentant la pose d'une carte sur le tableau
class DealtStep extends Equatable {
  const DealtStep({
    required this.card,
    required this.column,
    required this.isLastInColumn,
    required this.stepIndex,
  });

  /// La carte à distribuer
  final Card card;

  /// Index de la colonne de destination (0..6)
  final int column;

  /// Indique si cette carte est la dernière de sa colonne (doit être retournée face up)
  final bool isLastInColumn;

  /// Index de cette étape dans la séquence (0..27)
  final int stepIndex;

  @override
  List<Object?> get props => [card, column, isLastInColumn, stepIndex];

  @override
  String toString() =>
      'DealtStep(${card.rank}${card.suit} -> col$column${isLastInColumn ? ' FLIP' : ''})';
}

/// Plan complet de distribution pour une partie Klondike
class DealtPlan extends Equatable {
  const DealtPlan({
    required this.steps,
    required this.remainingCards,
    required this.seed,
    required this.drawMode,
  });

  /// Les 28 étapes de distribution dans l'ordre chronologique
  final List<DealtStep> steps;

  /// Les 24 cartes restantes qui iront dans le stock
  final List<Card> remainingCards;

  /// Seed utilisé pour la génération
  final int seed;

  /// Mode de pioche configuré
  final DrawMode drawMode;

  /// Vérifications de cohérence
  bool get isValid {
    // Doit y avoir exactement 28 étapes (7+6+5+4+3+2+1)
    if (steps.length != 28) return false;

    // Plus 24 cartes restantes = 52 cartes total
    if (remainingCards.length != 24) return false;

    // Vérifier que chaque colonne reçoit le bon nombre de cartes
    final cardsPerColumn = List.filled(7, 0);
    for (final step in steps) {
      if (step.column < 0 || step.column >= 7) return false;
      cardsPerColumn[step.column]++;
    }

    // Colonne i doit recevoir i+1 cartes
    for (var i = 0; i < 7; i++) {
      if (cardsPerColumn[i] != i + 1) return false;
    }

    // Vérifier que la dernière carte de chaque colonne est marquée pour flip
    final lastStepPerColumn = <int, int>{};
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      lastStepPerColumn[step.column] = i;
    }

    for (final columnIndex in lastStepPerColumn.keys) {
      final lastStepIndex = lastStepPerColumn[columnIndex]!;
      if (!steps[lastStepIndex].isLastInColumn) return false;
    }

    // Toutes les cartes doivent être uniques
    final allCards = [...steps.map((s) => s.card), ...remainingCards];
    final uniqueIds = allCards.map((c) => c.id).toSet();
    if (uniqueIds.length != 52) return false;

    return true;
  }

  @override
  List<Object?> get props => [steps, remainingCards, seed, drawMode];

  @override
  String toString() => 'DealtPlan(${steps.length} steps, seed: $seed)';
}
