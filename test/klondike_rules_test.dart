import 'package:flutter_test/flutter_test.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/klondike_rules.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/dealer_service.dart';

void main() {
  group('KlondikeRules', () {
    late KlondikeRules rules;
    late DealerService dealer;

    setUp(() {
      rules = const KlondikeRules();
      dealer = const DealerService();
    });

    group('Card placement rules', () {
      test(
          'card can be placed on tableau with alternating color and descending rank',
          () {
        const redSeven = Card(
          suit: Suit.hearts,
          rank: Rank.seven,
          faceUp: true,
        );
        const blackSix = Card(
          suit: Suit.spades,
          rank: Rank.six,
          faceUp: true,
        );

        expect(blackSix.canBePlacedOnTableau(redSeven), isTrue);
        expect(redSeven.canBePlacedOnTableau(blackSix), isFalse);
      });

      test('king can be placed on empty tableau pile', () {
        const king = Card(
          suit: Suit.spades,
          rank: Rank.king,
          faceUp: true,
        );

        expect(king.canBePlacedOnTableau(null), isTrue);
      });

      test('non-king cannot be placed on empty tableau pile', () {
        const queen = Card(
          suit: Suit.hearts,
          rank: Rank.queen,
          faceUp: true,
        );

        expect(queen.canBePlacedOnTableau(null), isFalse);
      });

      test('ace can be placed on empty foundation', () {
        const ace = Card(
          suit: Suit.diamonds,
          rank: Rank.ace,
          faceUp: true,
        );

        expect(ace.canBePlacedOnFoundation(null), isTrue);
      });

      test('card can be placed on foundation with same suit and ascending rank',
          () {
        const ace = Card(
          suit: Suit.clubs,
          rank: Rank.ace,
          faceUp: true,
        );
        const two = Card(
          suit: Suit.clubs,
          rank: Rank.two,
          faceUp: true,
        );

        expect(two.canBePlacedOnFoundation(ace), isTrue);
      });

      test('card cannot be placed on foundation with different suit', () {
        const aceClubs = Card(
          suit: Suit.clubs,
          rank: Rank.ace,
          faceUp: true,
        );
        const twoHearts = Card(
          suit: Suit.hearts,
          rank: Rank.two,
          faceUp: true,
        );

        expect(twoHearts.canBePlacedOnFoundation(aceClubs), isFalse);
      });
    });

    group('Move validation', () {
      test('can draw from stock when stock is not empty', () {
        final gameState = dealer.dealNewGame(seed: 42);
        final move = Move.stockToWaste(cards: [gameState.stock.topCard!]);

        expect(rules.isMoveLegal(move, gameState), isTrue);
      });

      test('cannot draw from empty stock', () {
        final gameState = GameState.initial(seed: 42).copyWith(
          stock: const Pile.empty(PileType.stock),
        );
        final move = Move.stockToWaste(cards: const []);

        expect(rules.isMoveLegal(move, gameState), isFalse);
      });

      test('can move waste card to valid tableau position', () {
        const wasteCard = Card(
          suit: Suit.spades,
          rank: Rank.six,
          faceUp: true,
        );
        const tableauCard = Card(
          suit: Suit.hearts,
          rank: Rank.seven,
          faceUp: true,
        );

        final gameState = GameState.initial(seed: 42).copyWith(
          waste: const Pile(type: PileType.waste, cards: [wasteCard]),
          tableau: [
            const Pile(type: PileType.tableau, cards: [tableauCard], index: 0),
            ...List.generate(
              6,
              (i) => Pile.empty(PileType.tableau, index: i + 1),
            ),
          ],
        );

        const move = Move.wasteToTableau(tableauIndex: 0, card: wasteCard);
        expect(rules.isMoveLegal(move, gameState), isTrue);
      });

      test('cannot move waste card to invalid tableau position', () {
        const wasteCard = Card(
          suit: Suit.spades,
          rank: Rank.six,
          faceUp: true,
        );
        const tableauCard = Card(
          suit: Suit.clubs,
          rank: Rank.five,
          faceUp: true,
        );

        final gameState = GameState.initial(seed: 42).copyWith(
          waste: const Pile(type: PileType.waste, cards: [wasteCard]),
          tableau: [
            const Pile(type: PileType.tableau, cards: [tableauCard], index: 0),
            ...List.generate(
              6,
              (i) => Pile.empty(PileType.tableau, index: i + 1),
            ),
          ],
        );

        const move = Move.wasteToTableau(tableauIndex: 0, card: wasteCard);
        expect(rules.isMoveLegal(move, gameState), isFalse);
      });
    });

    group('Legal moves generation', () {
      test('generates stock to waste move when stock is not empty', () {
        final gameState = dealer.dealNewGame(seed: 42);
        final legalMoves = rules.getLegalMoves(gameState);

        expect(
          legalMoves.any((move) => move.type == MoveType.stockToWaste),
          isTrue,
        );
      });

      test('generates flip moves for face-down tableau cards', () {
        const hiddenCard = Card(
          suit: Suit.hearts,
          rank: Rank.queen,
          faceUp: false,
        );
        const visibleCard = Card(
          suit: Suit.spades,
          rank: Rank.king,
          faceUp: true,
        );

        final gameState = GameState.initial(seed: 42).copyWith(
          tableau: [
            const Pile(
              type: PileType.tableau,
              cards: [hiddenCard, visibleCard],
              index: 0,
            ),
            ...List.generate(
              6,
              (i) => Pile.empty(PileType.tableau, index: i + 1),
            ),
          ],
        );

        final legalMoves = rules.getLegalMoves(gameState);
        final flipMoves =
            legalMoves.where((move) => move.type == MoveType.flipTableauCard);

        expect(
          flipMoves,
          isEmpty,
        ); // Pas de flip car il y a une carte visible au-dessus
      });

      test('generates foundation moves for aces', () {
        const ace = Card(
          suit: Suit.hearts,
          rank: Rank.ace,
          faceUp: true,
        );

        final gameState = GameState.initial(seed: 42).copyWith(
          waste: const Pile(type: PileType.waste, cards: [ace]),
        );

        final legalMoves = rules.getLegalMoves(gameState);
        final foundationMoves = legalMoves.where(
          (move) => move.type == MoveType.wasteToFoundation,
        );

        expect(foundationMoves, isNotEmpty);
      });
    });

    group('Game state validation', () {
      test('recognizes won game when all foundations are complete', () {
        final foundations = Suit.values.map((suit) {
          final cards = Rank.values
              .map(
                (rank) => Card(
                  suit: suit,
                  rank: rank,
                  faceUp: true,
                ),
              )
              .toList();
          return Pile(
            type: PileType.foundation,
            cards: cards,
            index: suit.index,
          );
        }).toList();

        final gameState = GameState.initial(seed: 42).copyWith(
          foundations: foundations,
        );

        expect(rules.isGameWon(gameState), isTrue);
      });

      test('recognizes incomplete game when foundations are not complete', () {
        final gameState = dealer.dealNewGame(seed: 42);
        expect(rules.isGameWon(gameState), isFalse);
      });
    });

    group('Auto-move detection', () {
      test('detects auto-move for low-rank cards to foundations', () {
        const ace = Card(
          suit: Suit.hearts,
          rank: Rank.ace,
          faceUp: true,
        );

        final gameState = GameState.initial(seed: 42).copyWith(
          waste: const Pile(type: PileType.waste, cards: [ace]),
        );

        final autoMoves = rules.getAutoMoves(gameState);
        expect(autoMoves, isNotEmpty);
        expect(autoMoves.first.type, MoveType.wasteToFoundation);
      });

      test('does not detect auto-move for high-rank cards when unsafe', () {
        const king = Card(
          suit: Suit.hearts,
          rank: Rank.king,
          faceUp: true,
        );

        final gameState = GameState.initial(seed: 42).copyWith(
          waste: const Pile(type: PileType.waste, cards: [king]),
        );

        final autoMoves = rules.getAutoMoves(gameState);
        expect(autoMoves, isEmpty);
      });
    });

    group('Victory detection', () {
      test('isWin returns true when all foundations have 13 cards', () {
        // Créer un état avec toutes les fondations complètes
        final completeFoundations = [
          Pile(
            type: PileType.foundation,
            index: 0,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.hearts,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
          Pile(
            type: PileType.foundation,
            index: 1,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.diamonds,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
          Pile(
            type: PileType.foundation,
            index: 2,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.clubs,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
          Pile(
            type: PileType.foundation,
            index: 3,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.spades,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
        ];

        final winState = GameState.initial(seed: 42).copyWith(
          foundations: completeFoundations,
          stock: const Pile.empty(PileType.stock),
          waste: const Pile.empty(PileType.waste),
          tableau:
              List.generate(7, (i) => Pile.empty(PileType.tableau, index: i)),
        );

        expect(rules.isWin(winState), isTrue);
        expect(rules.isGameWon(winState), isTrue);
      });

      test('isWin returns false when foundations are incomplete', () {
        // Créer un état avec des fondations incomplètes
        final incompleteFoundations = [
          Pile(
            type: PileType.foundation,
            index: 0,
            cards: List.generate(
              12,
              (i) => Card(
                // Seulement 12 cartes
                suit: Suit.hearts,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
          Pile(
            type: PileType.foundation,
            index: 1,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.diamonds,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
          Pile(
            type: PileType.foundation,
            index: 2,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.clubs,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
          Pile(
            type: PileType.foundation,
            index: 3,
            cards: List.generate(
              13,
              (i) => Card(
                suit: Suit.spades,
                rank: Rank.values[i],
                faceUp: true,
              ),
            ),
          ),
        ];

        final notWinState = GameState.initial(seed: 42).copyWith(
          foundations: incompleteFoundations,
        );

        expect(rules.isWin(notWinState), isFalse);
        expect(rules.isGameWon(notWinState), isFalse);
      });

      test('isWin returns false for initial game state', () {
        final initialState = GameState.initial(seed: 42);
        expect(rules.isWin(initialState), isFalse);
        expect(rules.isGameWon(initialState), isFalse);
      });
    });
  });
}
