import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';

/// Service contenant toutes les règles du Solitaire Klondike
class KlondikeRules {
  const KlondikeRules();

  /// Vérifie si un mouvement est légal
  bool isMoveLegal(Move move, GameState gameState) {
    switch (move.type) {
      case MoveType.stockToWaste:
        return _canDrawFromStock(gameState);

      case MoveType.wasteToTableau:
        return _canMoveWasteToTableau(move.to!, gameState);

      case MoveType.wasteToFoundation:
        return _canMoveWasteToFoundation(move.to!, gameState);

      case MoveType.tableauToTableau:
        return _canMoveTableauToTableau(
          move.from,
          move.to!,
          move.cards,
          gameState,
        );

      case MoveType.tableauToFoundation:
        return _canMoveTableauToFoundation(move.from, move.to!, gameState);

      case MoveType.foundationToTableau:
        return _canMoveFoundationToTableau(move.from, move.to!, gameState);

      case MoveType.flipTableauCard:
        return _canFlipTableauCard(move.from, gameState);

      case MoveType.resetStock:
        return _canResetStock(gameState);
    }
  }

  /// Vérifie si on peut piocher du stock
  bool _canDrawFromStock(GameState gameState) {
    return gameState.stock.isNotEmpty;
  }

  /// Vérifie si on peut déplacer la carte de la défausse vers le tableau
  bool _canMoveWasteToTableau(int tableauIndex, GameState gameState) {
    if (gameState.waste.isEmpty) return false;
    if (tableauIndex < 0 || tableauIndex >= gameState.tableau.length)
      return false;

    final wasteCard = gameState.waste.topCard!;
    final tableauPile = gameState.tableau[tableauIndex];

    return tableauPile.canAcceptCard(wasteCard);
  }

  /// Vérifie si on peut déplacer la carte de la défausse vers une fondation
  bool _canMoveWasteToFoundation(int foundationIndex, GameState gameState) {
    if (gameState.waste.isEmpty) return false;
    if (foundationIndex < 0 || foundationIndex >= gameState.foundations.length)
      return false;

    final wasteCard = gameState.waste.topCard!;
    final foundationPile = gameState.foundations[foundationIndex];

    return foundationPile.canAcceptCard(wasteCard);
  }

  /// Vérifie si on peut déplacer des cartes entre piles du tableau
  bool _canMoveTableauToTableau(
    int fromIndex,
    int toIndex,
    List<Card> cardsToMove,
    GameState gameState,
  ) {
    if (fromIndex < 0 || fromIndex >= gameState.tableau.length) return false;
    if (toIndex < 0 || toIndex >= gameState.tableau.length) return false;
    if (fromIndex == toIndex) return false;
    if (cardsToMove.isEmpty) return false;

    final fromPile = gameState.tableau[fromIndex];
    final toPile = gameState.tableau[toIndex];

    // Vérifie que les cartes à déplacer sont bien au sommet de la pile source
    if (!_areCardsAtTop(fromPile, cardsToMove)) return false;

    // Vérifie que toutes les cartes à déplacer sont face visible
    if (!cardsToMove.every((card) => card.faceUp)) return false;

    // Vérifie que la séquence est valide (alternance couleur, décroissant)
    if (!_isValidTableauSequence(cardsToMove)) return false;

    // Vérifie que la pile de destination peut accepter les cartes
    return toPile.canAcceptCards(cardsToMove);
  }

  /// Vérifie si on peut déplacer une carte du tableau vers une fondation
  bool _canMoveTableauToFoundation(
    int tableauIndex,
    int foundationIndex,
    GameState gameState,
  ) {
    if (tableauIndex < 0 || tableauIndex >= gameState.tableau.length)
      return false;
    if (foundationIndex < 0 || foundationIndex >= gameState.foundations.length)
      return false;

    final tableauPile = gameState.tableau[tableauIndex];
    final foundationPile = gameState.foundations[foundationIndex];

    if (tableauPile.isEmpty) return false;

    final cardToMove = tableauPile.topCard!;
    if (!cardToMove.faceUp) return false;

    return foundationPile.canAcceptCard(cardToMove);
  }

  /// Vérifie si on peut déplacer une carte d'une fondation vers le tableau
  bool _canMoveFoundationToTableau(
    int foundationIndex,
    int tableauIndex,
    GameState gameState,
  ) {
    if (foundationIndex < 0 || foundationIndex >= gameState.foundations.length)
      return false;
    if (tableauIndex < 0 || tableauIndex >= gameState.tableau.length)
      return false;

    final foundationPile = gameState.foundations[foundationIndex];
    final tableauPile = gameState.tableau[tableauIndex];

    if (foundationPile.isEmpty) return false;

    final cardToMove = foundationPile.topCard!;
    return tableauPile.canAcceptCard(cardToMove);
  }

  /// Vérifie si on peut retourner une carte du tableau
  bool _canFlipTableauCard(int tableauIndex, GameState gameState) {
    if (tableauIndex < 0 || tableauIndex >= gameState.tableau.length)
      return false;

    final pile = gameState.tableau[tableauIndex];
    if (pile.isEmpty) return false;

    final topCard = pile.topCard!;
    return !topCard.faceUp;
  }

  /// Vérifie si on peut remettre les cartes de la défausse dans le stock
  bool _canResetStock(GameState gameState) {
    return gameState.stock.isEmpty && gameState.waste.isNotEmpty;
  }

  /// Vérifie que les cartes sont bien au sommet de la pile
  bool _areCardsAtTop(Pile pile, List<Card> cards) {
    if (cards.length > pile.length) return false;

    final startIndex = pile.length - cards.length;
    final topCards = pile.cards.sublist(startIndex);

    for (var i = 0; i < cards.length; i++) {
      if (topCards[i] != cards[i]) return false;
    }

    return true;
  }

  /// Vérifie qu'une séquence de cartes est valide pour le tableau
  bool _isValidTableauSequence(List<Card> cards) {
    if (cards.length <= 1) return true;

    for (var i = 1; i < cards.length; i++) {
      final previous = cards[i - 1];
      final current = cards[i];

      // Vérification de l'alternance de couleur et du rang décroissant
      if (!current.canBePlacedOnTableau(previous)) {
        return false;
      }
    }

    return true;
  }

  /// Retourne tous les mouvements légaux possibles dans l'état actuel
  List<Move> getLegalMoves(GameState gameState) {
    final moves = <Move>[];

    // Mouvements du stock vers la défausse
    if (_canDrawFromStock(gameState)) {
      final cardsToTake = gameState.drawMode == DrawMode.one ? 1 : 3;
      final cardsTaken = gameState.stock.cards
          .take(cardsToTake.clamp(0, gameState.stock.length))
          .toList();

      moves.add(Move.stockToWaste(cards: cardsTaken));
    }

    // Reset du stock si possible
    if (_canResetStock(gameState)) {
      moves
          .add(Move.resetStock(cards: gameState.waste.cards.reversed.toList()));
    }

    // Mouvements de la défausse
    if (gameState.waste.isNotEmpty) {
      final wasteCard = gameState.waste.topCard!;

      // Défausse vers tableau
      for (var i = 0; i < gameState.tableau.length; i++) {
        if (_canMoveWasteToTableau(i, gameState)) {
          moves.add(Move.wasteToTableau(tableauIndex: i, card: wasteCard));
        }
      }

      // Défausse vers fondations
      for (var i = 0; i < gameState.foundations.length; i++) {
        if (_canMoveWasteToFoundation(i, gameState)) {
          moves
              .add(Move.wasteToFoundation(foundationIndex: i, card: wasteCard));
        }
      }
    }

    // Mouvements du tableau
    for (var fromIndex = 0; fromIndex < gameState.tableau.length; fromIndex++) {
      final fromPile = gameState.tableau[fromIndex];

      if (fromPile.isEmpty) continue;

      // Retourner une carte face cachée
      if (_canFlipTableauCard(fromIndex, gameState)) {
        moves.add(
          Move.flipTableauCard(
            tableauIndex: fromIndex,
            card: fromPile.topCard!,
          ),
        );
      }

      // Mouvements vers les fondations
      if (fromPile.topCard!.faceUp) {
        for (var foundationIndex = 0;
            foundationIndex < gameState.foundations.length;
            foundationIndex++) {
          if (_canMoveTableauToFoundation(
            fromIndex,
            foundationIndex,
            gameState,
          )) {
            moves.add(
              Move.tableauToFoundation(
                tableauIndex: fromIndex,
                foundationIndex: foundationIndex,
                card: fromPile.topCard!,
              ),
            );
          }
        }

        // Mouvements vers d'autres piles du tableau
        final faceUpCards = fromPile.faceUpCards;
        if (faceUpCards.isNotEmpty) {
          for (var cardCount = 1;
              cardCount <= faceUpCards.length;
              cardCount++) {
            final cardsToMove =
                faceUpCards.sublist(faceUpCards.length - cardCount);

            for (var toIndex = 0;
                toIndex < gameState.tableau.length;
                toIndex++) {
              if (_canMoveTableauToTableau(
                fromIndex,
                toIndex,
                cardsToMove,
                gameState,
              )) {
                moves.add(
                  Move.tableauToTableau(
                    fromIndex: fromIndex,
                    toIndex: toIndex,
                    cards: cardsToMove,
                  ),
                );
              }
            }
          }
        }
      }
    }

    // Mouvements des fondations vers le tableau
    for (var foundationIndex = 0;
        foundationIndex < gameState.foundations.length;
        foundationIndex++) {
      final foundationPile = gameState.foundations[foundationIndex];

      if (foundationPile.isNotEmpty) {
        for (var tableauIndex = 0;
            tableauIndex < gameState.tableau.length;
            tableauIndex++) {
          if (_canMoveFoundationToTableau(
            foundationIndex,
            tableauIndex,
            gameState,
          )) {
            moves.add(
              Move.foundationToTableau(
                foundationIndex: foundationIndex,
                tableauIndex: tableauIndex,
                card: foundationPile.topCard!,
              ),
            );
          }
        }
      }
    }

    return moves;
  }

  /// Vérifie si la partie est dans un état de victoire
  bool isGameWon(GameState gameState) {
    return gameState.foundations.every((pile) => pile.length == 13);
  }

  /// Vérifie si on a une victoire (alias pour la compatibilité)
  bool isWin(GameState gameState) {
    return isGameWon(gameState);
  }

  /// Vérifie si la partie est dans un état de défaite (aucun mouvement possible)
  bool isGameLost(GameState gameState) {
    if (isGameWon(gameState)) return false;
    return getLegalMoves(gameState).isEmpty;
  }

  /// Vérifie si on peut effectuer un auto-move vers les fondations
  List<Move> getAutoMoves(GameState gameState) {
    final autoMoves = <Move>[];

    // Trouve le rang minimum dans les fondations pour chaque couleur
    final minRedRank = _getMinFoundationRank(gameState, CardColor.red);
    final minBlackRank = _getMinFoundationRank(gameState, CardColor.black);

    // Vérifie les cartes de la défausse
    if (gameState.waste.isNotEmpty) {
      final wasteCard = gameState.waste.topCard!;
      if (_canAutoMoveToFoundation(wasteCard, minRedRank, minBlackRank)) {
        for (var i = 0; i < gameState.foundations.length; i++) {
          if (_canMoveWasteToFoundation(i, gameState)) {
            autoMoves.add(
              Move.wasteToFoundation(foundationIndex: i, card: wasteCard),
            );
            break;
          }
        }
      }
    }

    // Vérifie les cartes du tableau
    for (var tableauIndex = 0;
        tableauIndex < gameState.tableau.length;
        tableauIndex++) {
      final pile = gameState.tableau[tableauIndex];
      if (pile.isNotEmpty && pile.topCard!.faceUp) {
        final topCard = pile.topCard!;
        if (_canAutoMoveToFoundation(topCard, minRedRank, minBlackRank)) {
          for (var foundationIndex = 0;
              foundationIndex < gameState.foundations.length;
              foundationIndex++) {
            if (_canMoveTableauToFoundation(
              tableauIndex,
              foundationIndex,
              gameState,
            )) {
              autoMoves.add(
                Move.tableauToFoundation(
                  tableauIndex: tableauIndex,
                  foundationIndex: foundationIndex,
                  card: topCard,
                ),
              );
              break;
            }
          }
        }
      }
    }

    return autoMoves;
  }

  /// Obtient le rang minimum dans les fondations pour une couleur donnée
  int _getMinFoundationRank(GameState gameState, CardColor color) {
    var minRank = 14; // Plus que le roi

    for (final foundation in gameState.foundations) {
      if (foundation.isEmpty) {
        minRank = 0; // Aucune carte, donc As possible
      } else {
        final topCard = foundation.topCard!;
        if (topCard.color == color) {
          minRank = minRank < topCard.rank.value ? minRank : topCard.rank.value;
        }
      }
    }

    return minRank == 14 ? 0 : minRank;
  }

  /// Vérifie si une carte peut être automatiquement déplacée vers les fondations
  bool _canAutoMoveToFoundation(Card card, int minRedRank, int minBlackRank) {
    final minOppositeColorRank =
        card.color == CardColor.red ? minBlackRank : minRedRank;

    // Les As et les 2 peuvent toujours être automatiquement déplacés
    if (card.rank.value <= 2) return true;

    // Une carte peut être automatiquement déplacée si elle ne bloque pas
    // les cartes de couleur opposée (règle de sécurité)
    return card.rank.value <= minOppositeColorRank + 1;
  }
}
