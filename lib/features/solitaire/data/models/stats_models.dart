/// Mode de pioche (1 carte ou 3 cartes)
enum DrawMode {
  draw1,
  draw3,
}

/// Session de jeu persistée pour les statistiques
class GameSession {
  // partie quittée

  GameSession({
    required this.id,
    required this.seed,
    required this.drawMode,
    required this.won,
    required this.moves,
    required this.elapsedMs,
    required this.scoreStandard,
    required this.scoreVegas,
    required this.startedAt,
    required this.endedAt,
    this.aborted = false,
  });
  String id; // uuid
  int seed;
  DrawMode drawMode;
  bool won;
  int moves; // nombre de coups
  int elapsedMs; // durée en millisecondes
  int scoreStandard; // scoring "classic"
  int scoreVegas; // delta vegas pour cette partie
  DateTime startedAt;
  DateTime endedAt;
  bool aborted;

  /// Durée de la partie
  Duration get duration => Duration(milliseconds: elapsedMs);

  /// Date seulement (sans l'heure) pour le groupement par jour
  DateTime get dateOnly => DateTime(
        endedAt.year,
        endedAt.month,
        endedAt.day,
      );

  @override
  String toString() =>
      'GameSession($id, won: $won, moves: $moves, duration: ${duration.inSeconds}s)';
}

/// Totaux cumulés des statistiques
class StatsTotals {
  StatsTotals({
    this.games = 0,
    this.wins = 0,
    this.sumElapsedMs = 0,
    this.sumMoves = 0,
    this.bestTimeMs = 0,
    this.bestMoves = 0,
    this.vegasBankroll = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
  });
  int games; // total parties jouées
  int wins; // total parties gagnées
  int sumElapsedMs; // pour calcul de la moyenne
  int sumMoves;
  int bestTimeMs; // meilleur temps (min non-0)
  int bestMoves; // minimum de coups quand won
  int vegasBankroll; // cumul Vegas
  int currentWinStreak;
  int bestWinStreak;

  /// Taux de victoire (0.0 à 1.0)
  double get winRate => games > 0 ? wins / games : 0.0;

  /// Temps moyen par partie
  Duration get avgTime =>
      games > 0 ? Duration(milliseconds: sumElapsedMs ~/ games) : Duration.zero;

  /// Nombre moyen de coups par partie
  double get avgMoves => games > 0 ? sumMoves / games : 0.0;

  /// Meilleur temps (ou Duration.zero si pas encore de temps)
  Duration get bestTime =>
      bestTimeMs > 0 ? Duration(milliseconds: bestTimeMs) : Duration.zero;

  @override
  String toString() =>
      'StatsTotals(games: $games, wins: $wins, winRate: ${(winRate * 100).toStringAsFixed(1)}%)';
}

/// Point de données pour les tendances temporelles
class TimePoint {
  const TimePoint({
    required this.date,
    required this.wins,
    required this.games,
  });
  final DateTime date;
  final int wins;
  final int games;

  double get winRate => games > 0 ? wins / games : 0.0;

  @override
  String toString() => 'TimePoint(${date.day}/${date.month}: $wins/$games)';
}

/// Filtres pour les statistiques
enum StatsRange {
  today,
  week,
  month,
  all,
}

extension StatsRangeExtension on StatsRange {
  String get key {
    switch (this) {
      case StatsRange.today:
        return 'today';
      case StatsRange.week:
        return 'week';
      case StatsRange.month:
        return 'month';
      case StatsRange.all:
        return 'all';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case StatsRange.today:
        return DateTime(now.year, now.month, now.day);
      case StatsRange.week:
        return now.subtract(const Duration(days: 7));
      case StatsRange.month:
        return now.subtract(const Duration(days: 30));
      case StatsRange.all:
        return null; // Pas de limite
    }
  }
}

/// Filtres de statistiques
class StatsFilter {
  const StatsFilter({
    this.range = StatsRange.all,
    this.drawMode,
  });
  final StatsRange range;
  final DrawMode? drawMode;

  StatsFilter copyWith({
    StatsRange? range,
    DrawMode? drawMode,
  }) {
    return StatsFilter(
      range: range ?? this.range,
      drawMode: drawMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsFilter &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          drawMode == other.drawMode;

  @override
  int get hashCode => range.hashCode ^ drawMode.hashCode;

  @override
  String toString() => 'StatsFilter(range: $range, drawMode: $drawMode)';
}
