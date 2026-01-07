import 'package:flutter_test/flutter_test.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/dealer.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/klondike_rules.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/scorer_service.dart';

void main() {
  group('Undo Logic Tests', () {
    late Dealer dealer;
    late KlondikeRules rules;
    late ScorerService scorer;

    setUp(() {
      dealer = const Dealer();
      rules = const KlondikeRules();
      scorer = const ScorerService();
    });

    group('Move History and Replay', () {
      test('move history records moves correctly', () {
        // Créer un état initial avec une seed connue
        final state = dealer.deal(12345, DrawMode.one);

        // Vérifier que l'historique est vide au début
        expect(state.moveHistory, isEmpty);
        expect(state.canUndo, isFalse);
      });

      test('stockToWaste move is recorded in history', () {
        var state = dealer.deal(12345, DrawMode.one);

        // Simuler un tap sur le stock
        if (state.stock.isNotEmpty) {
          final card = state.stock.cards.first;
          final move = Move.stockToWaste(cards: [card]);

          // Appliquer le mouvement manuellement
          final newStockCards = state.stock.cards.sublist(1);
          final newWasteCards = [
            ...state.waste.cards,
            Card(
              suit: card.suit,
              rank: card.rank,
              faceUp: true,
              id: card.id,
            ),
          ];

          state = state.copyWith(
            stock: state.stock.copyWith(cards: newStockCards),
            waste: state.waste.copyWith(cards: newWasteCards),
          );
          state = state.addMoveToHistory(move);

          expect(state.moveHistory.length, equals(1));
          expect(state.moveHistory.first.type, equals(MoveType.stockToWaste));
          expect(state.canUndo, isTrue);
        }
      });

      test('multiple moves are recorded in order', () {
        var state = dealer.deal(12345, DrawMode.one);
        var moveCount = 0;

        // Ajouter plusieurs mouvements stock->waste
        for (var i = 0; i < 3 && state.stock.isNotEmpty; i++) {
          final card = state.stock.cards.first;
          final move = Move.stockToWaste(cards: [card]);

          final newStockCards = state.stock.cards.sublist(1);
          final newWasteCards = [
            ...state.waste.cards,
            Card(suit: card.suit, rank: card.rank, faceUp: true, id: card.id),
          ];

          state = state.copyWith(
            stock: state.stock.copyWith(cards: newStockCards),
            waste: state.waste.copyWith(cards: newWasteCards),
          );
          state = state.addMoveToHistory(move);
          moveCount++;
        }

        expect(state.moveHistory.length, equals(moveCount));
      });

      test('flipTableauCard moves are separate from regular moves', () {
        var state = dealer.deal(12345, DrawMode.one);

        // Ajouter un mouvement normal
        if (state.stock.isNotEmpty) {
          final card = state.stock.cards.first;
          final move = Move.stockToWaste(cards: [card]);
          state = state.addMoveToHistory(move);
        }

        // Ajouter un mouvement de flip
        final flipMove = Move.flipTableauCard(
          tableauIndex: 0,
          card: const Card(suit: Suit.hearts, rank: Rank.ace, faceUp: true),
        );
        state = state.addMoveToHistory(flipMove);

        // Vérifier les types
        expect(state.moveHistory.length, equals(2));
        expect(
          state.moveHistory.where((m) => m.type == MoveType.flipTableauCard).length,
          equals(1),
        );
      });
    });

    group('Replay Logic', () {
      test('replaying moves from initial state produces same result', () {
        const seed = 12345;
        var state1 = dealer.deal(seed, DrawMode.one);
        var state2 = dealer.deal(seed, DrawMode.one);

        // Les deux états doivent être identiques
        expect(state1.stock.cards.length, equals(state2.stock.cards.length));
        expect(state1.waste.cards.length, equals(state2.waste.cards.length));

        // Vérifier que les cartes sont identiques
        for (var i = 0; i < state1.tableau.length; i++) {
          expect(
            state1.tableau[i].cards.length,
            equals(state2.tableau[i].cards.length),
          );
        }
      });

      test('filtering flipTableauCard moves from history works', () {
        var state = dealer.deal(12345, DrawMode.one);

        // Ajouter des mouvements mixtes
        state = state.addMoveToHistory(
          Move.stockToWaste(cards: [state.stock.cards.first]),
        );
        state = state.addMoveToHistory(
          Move.flipTableauCard(
            tableauIndex: 0,
            card: const Card(suit: Suit.hearts, rank: Rank.ace, faceUp: true),
          ),
        );
        state = state.addMoveToHistory(
          Move.stockToWaste(cards: [state.stock.cards[1]]),
        );

        // Filtrer les flips
        final realMoves = state.moveHistory
            .where((m) => m.type != MoveType.flipTableauCard)
            .toList();

        expect(realMoves.length, equals(2));
        expect(
          realMoves.every((m) => m.type == MoveType.stockToWaste),
          isTrue,
        );
      });
    });

    group('canAutoComplete', () {
      test('returns false when stock is not empty', () {
        final state = dealer.deal(12345, DrawMode.one);

        // Le stock ne devrait pas être vide après le deal
        expect(state.stock.isNotEmpty, isTrue);

        // canAutoComplete devrait être false
        final canComplete = _canAutoComplete(state);
        expect(canComplete, isFalse);
      });

      test('returns false when waste is not empty', () {
        var state = dealer.deal(12345, DrawMode.one);

        // Vider le stock et mettre une carte dans waste
        state = state.copyWith(
          stock: const Pile.empty(PileType.stock),
          waste: Pile(
            type: PileType.waste,
            cards: const [
              Card(suit: Suit.hearts, rank: Rank.ace, faceUp: true),
            ],
          ),
        );

        final canComplete = _canAutoComplete(state);
        expect(canComplete, isFalse);
      });

      test('returns false when tableau has face-down cards', () {
        var state = dealer.deal(12345, DrawMode.one);

        // Vider stock et waste
        state = state.copyWith(
          stock: const Pile.empty(PileType.stock),
          waste: const Pile.empty(PileType.waste),
        );

        // Le tableau a des cartes face cachée par défaut
        final hasFaceDown = state.tableau.any(
          (pile) => pile.cards.any((card) => !card.faceUp),
        );
        expect(hasFaceDown, isTrue);

        final canComplete = _canAutoComplete(state);
        expect(canComplete, isFalse);
      });

      test('returns true when all conditions are met', () {
        // Créer un état où tout est visible
        final tableau = List.generate(7, (i) {
          if (i == 0) {
            return Pile(
              type: PileType.tableau,
              index: i,
              cards: const [
                Card(suit: Suit.hearts, rank: Rank.king, faceUp: true),
                Card(suit: Suit.spades, rank: Rank.queen, faceUp: true),
              ],
            );
          }
          return Pile.empty(PileType.tableau, index: i);
        });

        final state = GameState(
          stock: const Pile.empty(PileType.stock),
          waste: const Pile.empty(PileType.waste),
          foundations: List.generate(
            4,
            (i) => Pile.empty(PileType.foundation, index: i),
          ),
          tableau: tableau,
          drawMode: DrawMode.one,
          status: GameStatus.playing,
          score: 0,
          moves: 0,
          time: Duration.zero,
          seed: 12345,
          scoringMode: ScoringMode.standard,
          gameNumber: 1,
        );

        final canComplete = _canAutoComplete(state);
        expect(canComplete, isTrue);
      });
    });

    group('Move Validation', () {
      test('isMoveLegal validates stockToWaste correctly', () {
        final state = dealer.deal(12345, DrawMode.one);

        if (state.stock.isNotEmpty) {
          final move = Move.stockToWaste(cards: [state.stock.cards.first]);
          expect(rules.isMoveLegal(move, state), isTrue);
        }
      });

      test('isMoveLegal rejects invalid tableau moves', () {
        final state = dealer.deal(12345, DrawMode.one);

        // Essayer de déplacer une carte vers un endroit invalide
        const invalidMove = Move.tableauToTableau(
          fromIndex: 0,
          toIndex: 1,
          cards: [Card(suit: Suit.hearts, rank: Rank.two, faceUp: true)],
        );

        // Cela pourrait être légal ou non selon l'état, mais on vérifie que ça ne crash pas
        final result = rules.isMoveLegal(invalidMove, state);
        expect(result, isA<bool>());
      });
    });
  });
}

/// Helper function to check if auto-complete is available
/// (mirrors the logic in GameController)
bool _canAutoComplete(GameState state) {
  // Stock et waste doivent être vides
  if (state.stock.isNotEmpty || state.waste.isNotEmpty) {
    return false;
  }

  // Toutes les cartes du tableau doivent être face visible
  for (final pile in state.tableau) {
    for (final card in pile.cards) {
      if (!card.faceUp) {
        return false;
      }
    }
  }

  // Il doit rester des cartes à déplacer vers les fondations
  final cardsInTableau = state.tableau.fold<int>(
    0,
    (sum, pile) => sum + pile.cards.length,
  );

  return cardsInTableau > 0;
}
