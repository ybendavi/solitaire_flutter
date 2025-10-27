import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';

/// Service responsable du calcul des scores
class ScorerService {
  const ScorerService();

  /// Calcule les points gagnés pour un mouvement donné
  int calculateMoveScore(Move move, GameState gameState) {
    switch (gameState.scoringMode) {
      case ScoringMode.standard:
        return _calculateStandardScore(move, gameState);
      case ScoringMode.vegas:
        return _calculateVegasScore(move, gameState);
    }
  }

  /// Calcule le score selon le mode Standard
  int _calculateStandardScore(Move move, GameState gameState) {
    switch (move.type) {
      case MoveType.wasteToFoundation:
      case MoveType.tableauToFoundation:
        return 10; // +10 points pour placer une carte sur une fondation

      case MoveType.foundationToTableau:
        return -15; // -15 points pour retirer une carte d'une fondation

      case MoveType.flipTableauCard:
        return 5; // +5 points pour retourner une carte

      case MoveType.stockToWaste:
        // Pénalité si on fait plusieurs passages dans le stock
        if (gameState.stockTurns > 0) {
          return gameState.drawMode == DrawMode.one ? -1 : -2;
        }
        return 0;

      case MoveType.resetStock:
        return -100; // Pénalité pour remettre les cartes dans le stock

      case MoveType.wasteToTableau:
      case MoveType.tableauToTableau:
        return 0; // Pas de points pour ces mouvements
    }
  }

  /// Calcule le score selon le mode Vegas
  int _calculateVegasScore(Move move, GameState gameState) {
    switch (move.type) {
      case MoveType.wasteToFoundation:
      case MoveType.tableauToFoundation:
        return 5; // +5$ pour placer une carte sur une fondation

      case MoveType.foundationToTableau:
        return -5; // -5$ pour retirer une carte d'une fondation

      case MoveType.stockToWaste:
      case MoveType.resetStock:
      case MoveType.flipTableauCard:
      case MoveType.wasteToTableau:
      case MoveType.tableauToTableau:
        return 0; // Pas de points pour ces mouvements en mode Vegas
    }
  }

  /// Calcule le bonus de temps pour une partie gagnée
  int calculateTimeBonus(Duration gameTime, ScoringMode scoringMode) {
    if (scoringMode == ScoringMode.vegas) {
      return 0; // Pas de bonus de temps en mode Vegas
    }

    // Bonus basé sur le temps (mode Standard)
    final minutes = gameTime.inMinutes;
    if (minutes < 2) return 10000; // Moins de 2 minutes
    if (minutes < 5) return 5000; // Moins de 5 minutes
    if (minutes < 10) return 2000; // Moins de 10 minutes
    if (minutes < 20) return 1000; // Moins de 20 minutes
    return 0; // Pas de bonus au-delà
  }

  /// Calcule le bonus de mouvements pour une partie gagnée
  int calculateMoveBonus(int moves, ScoringMode scoringMode) {
    if (scoringMode == ScoringMode.vegas) {
      return 0; // Pas de bonus de mouvements en mode Vegas
    }

    // Bonus inversement proportionnel au nombre de mouvements
    if (moves < 100) return 5000; // Très efficace
    if (moves < 150) return 2000; // Efficace
    if (moves < 200) return 1000; // Bon
    return 0; // Pas de bonus
  }

  /// Calcule le score final d'une partie gagnée
  int calculateFinalScore(GameState gameState) {
    if (!gameState.isWon) return gameState.score;

    var finalScore = gameState.score;

    // Ajouter les bonus pour le mode Standard
    if (gameState.scoringMode == ScoringMode.standard) {
      finalScore += calculateTimeBonus(gameState.time, gameState.scoringMode);
      finalScore += calculateMoveBonus(gameState.moves, gameState.scoringMode);

      // Bonus pour avoir utilisé peu d'indices
      if (gameState.hintsUsed == 0) {
        finalScore += 1000; // Bonus pour ne pas avoir utilisé d'indices
      } else if (gameState.hintsUsed <= 3) {
        finalScore += 500; // Bonus pour avoir utilisé peu d'indices
      }
    }

    return finalScore.clamp(0, 999999); // Limite le score maximum
  }

  /// Calcule l'efficacité d'une partie (pourcentage)
  double calculateEfficiency(GameState gameState) {
    // Calcul basé sur le ratio mouvements optimaux / mouvements réels
    const optimalMoves = 76; // Estimation du nombre optimal de mouvements

    if (gameState.moves == 0) return 0;

    final efficiency = (optimalMoves / gameState.moves) * 100;
    return efficiency.clamp(0.0, 100.0);
  }

  /// Retourne une évaluation textuelle de la performance
  String getPerformanceRating(GameState gameState) {
    if (!gameState.isWon) return 'Non terminé';

    final efficiency = calculateEfficiency(gameState);
    final timeMinutes = gameState.time.inMinutes;

    if (efficiency >= 90 && timeMinutes < 3) return 'Exceptionnel';
    if (efficiency >= 80 && timeMinutes < 5) return 'Excellent';
    if (efficiency >= 70 && timeMinutes < 10) return 'Très bien';
    if (efficiency >= 60 && timeMinutes < 15) return 'Bien';
    if (efficiency >= 50 && timeMinutes < 30) return 'Correct';
    return 'À améliorer';
  }

  /// Calcule les statistiques détaillées d'une partie
  Map<String, dynamic> calculateGameStats(GameState gameState) {
    return {
      'score': gameState.score,
      'finalScore': calculateFinalScore(gameState),
      'moves': gameState.moves,
      'time': gameState.time.inSeconds,
      'timeFormatted': _formatDuration(gameState.time),
      'efficiency': calculateEfficiency(gameState),
      'hintsUsed': gameState.hintsUsed,
      'stockTurns': gameState.stockTurns,
      'performance': getPerformanceRating(gameState),
      'timeBonus': calculateTimeBonus(gameState.time, gameState.scoringMode),
      'moveBonus': calculateMoveBonus(gameState.moves, gameState.scoringMode),
      'scoringMode': gameState.scoringMode.name,
      'drawMode': gameState.drawMode.name,
    };
  }

  /// Formate une durée en chaîne lisible
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
  }

  /// Calcule le score pour une partie Vegas cumulée
  int calculateVegasCumulativeScore(
      List<int> previousScores, int currentScore) {
    final total =
        previousScores.fold(0, (sum, score) => sum + score) + currentScore;
    return total.clamp(-999999, 999999);
  }

  /// Détermine si un score Vegas est positif (bénéficiaire)
  bool isVegasScoreProfitable(int score) {
    return score > 0;
  }

  /// Calcule les points par minute
  double calculatePointsPerMinute(int score, Duration time) {
    if (time.inMinutes == 0) return 0;
    return score / time.inMinutes;
  }
}
