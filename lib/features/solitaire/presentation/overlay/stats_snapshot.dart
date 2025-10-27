import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';

/// Snapshot des statistiques de la partie en cours pour l'affichage
class StatsSnapshot {
  const StatsSnapshot({
    required this.time,
    required this.moves,
    required this.score,
    required this.scoringMode,
  });

  /// Crée un snapshot depuis l'état du jeu
  factory StatsSnapshot.fromState(GameState state) {
    return StatsSnapshot(
      time: state.time,
      moves: state.moves,
      score: state.score,
      scoringMode: state.scoringMode,
    );
  }

  final Duration time;
  final int moves;
  final int score;
  final ScoringMode scoringMode;

  /// Formate le temps sous forme lisible (mm:ss)
  String get formattedTime {
    final minutes = time.inMinutes;
    final seconds = time.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Indique si c'est le mode Vegas
  bool get isVegas => scoringMode == ScoringMode.vegas;
}
