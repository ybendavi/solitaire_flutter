/// Résultat possible d'une partie de Solitaire
enum GameResult {
  /// Partie gagnée
  win,

  /// Partie perdue
  loss,
}

extension GameResultExtension on GameResult {
  /// Indique si le résultat est une victoire
  bool get isWin => this == GameResult.win;

  /// Indique si le résultat est une défaite
  bool get isLoss => this == GameResult.loss;
}
