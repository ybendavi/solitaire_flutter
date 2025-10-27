import 'package:flutter_test/flutter_test.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_result.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/stats_snapshot.dart';

void main() {
  group('Victory Functionality', () {
    test('Victory state includes gameOver and gameResult', () {
      final winState = _createWinState().copyWith(
        gameOver: true,
        gameResult: GameResult.win,
      );

      expect(winState.gameOver, isTrue);
      expect(winState.gameResult, GameResult.win);
      expect(winState.gameResult?.isWin, isTrue);
    });

    test('Victory state includes gameOver and gameResult', () {
      final winState = _createWinState().copyWith(
        gameOver: true,
        gameResult: GameResult.win,
      );

      expect(winState.gameOver, isTrue);
      expect(winState.gameResult, GameResult.win);
      expect(winState.gameResult?.isWin, isTrue);
    });

    test('GameResult enum works correctly', () {
      expect(GameResult.win.isWin, isTrue);
      expect(GameResult.win.isLoss, isFalse);
      expect(GameResult.loss.isWin, isFalse);
      expect(GameResult.loss.isLoss, isTrue);
    });

    test('StatsSnapshot formats time correctly', () {
      final gameState = GameState.initial(seed: 42).copyWith(
        time: const Duration(minutes: 3, seconds: 45),
        moves: 150,
        score: 1200,
        scoringMode: ScoringMode.standard,
      );

      final snapshot = StatsSnapshot.fromState(gameState);

      expect(snapshot.formattedTime, '03:45');
      expect(snapshot.moves, 150);
      expect(snapshot.score, 1200);
      expect(snapshot.isVegas, isFalse);
    });

    test('StatsSnapshot detects Vegas mode correctly', () {
      final gameState = GameState.initial(seed: 42).copyWith(
        scoringMode: ScoringMode.vegas,
        score: -25,
      );

      final snapshot = StatsSnapshot.fromState(gameState);

      expect(snapshot.isVegas, isTrue);
      expect(snapshot.score, -25);
    });
  });
}

/// Crée un état de jeu de victoire pour les tests
GameState _createWinState() {
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

  return GameState.initial(seed: 42).copyWith(
    foundations: completeFoundations,
    stock: const Pile.empty(PileType.stock),
    waste: const Pile.empty(PileType.waste),
    tableau: List.generate(7, (i) => Pile.empty(PileType.tableau, index: i)),
    status: GameStatus.won,
  );
}
