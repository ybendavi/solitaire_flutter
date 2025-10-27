import 'package:equatable/equatable.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_result.dart';

/// Modes de pioche disponibles
enum DrawMode { one, three }

/// États possibles du jeu
enum GameStatus {
  playing, // Partie en cours
  won, // Partie gagnée
  paused, // Partie en pause
  dealing, // Distribution des cartes en cours
}

/// Types de scoring
enum ScoringMode {
  standard, // Score standard
  vegas, // Score Vegas
}

/// État complet du jeu Klondike
class GameState extends Equatable {
  const GameState({
    required this.stock,
    required this.waste,
    required this.foundations,
    required this.tableau,
    required this.drawMode,
    required this.status,
    required this.score,
    required this.moves,
    required this.time,
    required this.seed,
    this.moveHistory = const [],
    this.redoHistory = const [],
    this.scoringMode = ScoringMode.standard,
    this.gameNumber = 1,
    this.hintsUsed = 0,
    this.stockTurns = 0,
    this.gameOver = false,
    this.gameResult,
  }); // Coups annulés

  /// Crée un état de jeu initial
  factory GameState.initial({
    required int seed,
    DrawMode drawMode = DrawMode.one,
    ScoringMode scoringMode = ScoringMode.standard,
    int gameNumber = 1,
  }) {
    return GameState(
      stock: const Pile.empty(PileType.stock),
      waste: const Pile.empty(PileType.waste),
      foundations: List.generate(
        4,
        (index) => Pile.empty(PileType.foundation, index: index),
      ),
      tableau: List.generate(
        7,
        (index) => Pile.empty(PileType.tableau, index: index),
      ),
      drawMode: drawMode,
      status: GameStatus.playing,
      score: scoringMode == ScoringMode.vegas ? -52 : 0,
      moves: 0,
      time: Duration.zero,
      seed: seed,
      scoringMode: scoringMode,
      gameNumber: gameNumber,
    );
  }

  // Piles de jeu
  final Pile stock; // Talon
  final Pile waste; // Défausse
  final List<Pile> foundations; // 4 fondations (♠ ♥ ♦ ♣)
  final List<Pile> tableau; // 7 piles du tableau

  // Configuration du jeu
  final DrawMode drawMode; // Mode de pioche (1 ou 3)
  final GameStatus status; // État actuel du jeu
  final ScoringMode scoringMode; // Mode de score

  // Statistiques de la partie
  final int score; // Score actuel
  final int moves; // Nombre de coups joués
  final Duration time; // Temps écoulé
  final int seed; // Graine pour la reproductibilité
  final int gameNumber; // Numéro de la partie
  final int hintsUsed; // Nombre d'indices utilisés
  final int stockTurns; // Nombre de fois que le stock a été retourné

  // État de fin de partie
  final bool gameOver; // Partie terminée (victoire ou défaite)
  final GameResult? gameResult; // Résultat de la partie si terminée

  // Historique pour undo/redo
  final List<Move> moveHistory; // Historique des coups
  final List<Move> redoHistory;

  /// Vérifie si la partie est gagnée
  bool get isWon {
    return foundations.every((pile) => pile.length == 13);
  }

  /// Vérifie si on peut annuler un coup
  bool get canUndo => moveHistory.isNotEmpty;

  /// Vérifie si on peut refaire un coup
  bool get canRedo => redoHistory.isNotEmpty;

  /// Nombre total de cartes face visible dans le tableau
  int get tableauFaceUpCards {
    return tableau.fold(0, (sum, pile) => sum + pile.faceUpCards.length);
  }

  /// Nombre total de cartes dans les fondations
  int get foundationCards {
    return foundations.fold(0, (sum, pile) => sum + pile.length);
  }

  /// Vérifie si le stock peut être retourné
  bool get canResetStock {
    return stock.isEmpty && waste.isNotEmpty;
  }

  /// Retourne une fondation par enseigne
  Pile foundationForSuit(Suit suit) {
    return foundations[suit.index];
  }

  /// Retourne une pile du tableau par index
  Pile tableauPile(int index) {
    if (index < 0 || index >= tableau.length) {
      throw ArgumentError('Invalid tableau index: $index');
    }
    return tableau[index];
  }

  /// Crée une copie de l'état avec les paramètres modifiés
  GameState copyWith({
    Pile? stock,
    Pile? waste,
    List<Pile>? foundations,
    List<Pile>? tableau,
    DrawMode? drawMode,
    GameStatus? status,
    ScoringMode? scoringMode,
    int? score,
    int? moves,
    Duration? time,
    int? seed,
    int? gameNumber,
    int? hintsUsed,
    int? stockTurns,
    List<Move>? moveHistory,
    List<Move>? redoHistory,
    bool? gameOver,
    GameResult? gameResult,
  }) {
    return GameState(
      stock: stock ?? this.stock,
      waste: waste ?? this.waste,
      foundations: foundations ?? this.foundations,
      tableau: tableau ?? this.tableau,
      drawMode: drawMode ?? this.drawMode,
      status: status ?? this.status,
      scoringMode: scoringMode ?? this.scoringMode,
      score: score ?? this.score,
      moves: moves ?? this.moves,
      time: time ?? this.time,
      seed: seed ?? this.seed,
      gameNumber: gameNumber ?? this.gameNumber,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      stockTurns: stockTurns ?? this.stockTurns,
      moveHistory: moveHistory ?? this.moveHistory,
      redoHistory: redoHistory ?? this.redoHistory,
      gameOver: gameOver ?? this.gameOver,
      gameResult: gameResult ?? this.gameResult,
    );
  }

  /// Met à jour une pile du tableau
  GameState updateTableau(int index, Pile newPile) {
    final newTableau = [...tableau];
    newTableau[index] = newPile;
    return copyWith(tableau: newTableau);
  }

  /// Met à jour une fondation
  GameState updateFoundation(int index, Pile newPile) {
    final newFoundations = [...foundations];
    newFoundations[index] = newPile;
    return copyWith(foundations: newFoundations);
  }

  /// Ajoute un coup à l'historique et vide le redo
  GameState addMoveToHistory(Move move) {
    return copyWith(
      moveHistory: [...moveHistory, move],
      redoHistory: [], // Vider l'historique redo
      moves: moves + 1,
    );
  }

  /// Annule le dernier coup
  GameState undoLastMove() {
    if (!canUndo) return this;

    final lastMove = moveHistory.last;
    return copyWith(
      moveHistory: moveHistory.sublist(0, moveHistory.length - 1),
      redoHistory: [...redoHistory, lastMove],
    );
  }

  /// Refait le dernier coup annulé
  GameState redoLastMove() {
    if (!canRedo) return this;

    final moveToRedo = redoHistory.last;
    return copyWith(
      moveHistory: [...moveHistory, moveToRedo],
      redoHistory: redoHistory.sublist(0, redoHistory.length - 1),
    );
  }

  /// Met à jour le temps de jeu
  GameState updateTime(Duration newTime) {
    return copyWith(time: newTime);
  }

  /// Ajoute des points au score
  GameState addScore(int points) {
    return copyWith(score: score + points);
  }

  /// Utilise un indice
  GameState useHint() {
    return copyWith(hintsUsed: hintsUsed + 1);
  }

  /// Met la partie en pause
  GameState pause() {
    return copyWith(status: GameStatus.paused);
  }

  /// Reprend la partie
  GameState resume() {
    return copyWith(status: GameStatus.playing);
  }

  /// Marque la partie comme gagnée
  GameState win() {
    return copyWith(status: GameStatus.won);
  }

  @override
  List<Object?> get props => [
        stock,
        waste,
        foundations,
        tableau,
        drawMode,
        status,
        scoringMode,
        score,
        moves,
        time,
        seed,
        gameNumber,
        hintsUsed,
        stockTurns,
        moveHistory,
        redoHistory,
        gameOver,
        gameResult,
      ];

  @override
  String toString() {
    return 'GameState(moves: $moves, score: $score, time: $time, status: $status)';
  }
}
