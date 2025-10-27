import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_stats_repository.dart';

/// Provider pour le repository des statistiques
final statsRepositoryProvider = Provider<GameStatsRepository>((ref) {
  return GameStatsRepository();
});

/// Provider pour les filtres de statistiques
final statsFilterProvider = StateProvider<StatsFilter>((ref) {
  return const StatsFilter();
});

/// ViewModel pour les statistiques - prêt pour l'UI
class StatsViewModel {
  // 20 dernières

  const StatsViewModel({
    required this.games,
    required this.wins,
    required this.winRate,
    required this.bestTime,
    required this.avgTime,
    required this.avgMoves,
    required this.scoreStandardSum,
    required this.vegasBankroll,
    required this.currentStreak,
    required this.bestStreak,
    required this.trend7,
    required this.trend30,
    required this.recent,
  });

  factory StatsViewModel.empty() => const StatsViewModel(
        games: 0,
        wins: 0,
        winRate: 0,
        bestTime: Duration.zero,
        avgTime: Duration.zero,
        avgMoves: 0,
        scoreStandardSum: 0,
        vegasBankroll: 0,
        currentStreak: 0,
        bestStreak: 0,
        trend7: [],
        trend30: [],
        recent: [],
      );
  final int games;
  final int wins;
  final double winRate; // 0..1
  final Duration bestTime;
  final Duration avgTime;
  final double avgMoves;
  final int scoreStandardSum;
  final int vegasBankroll;
  final int currentStreak;
  final int bestStreak;
  final List<TimePoint> trend7; // {date, wins, games}
  final List<TimePoint> trend30;
  final List<GameSession> recent;

  @override
  String toString() =>
      'StatsViewModel(games: $games, winRate: ${(winRate * 100).toStringAsFixed(1)}%)';
}

/// Contrôleur pour les statistiques
class StatsController extends AsyncNotifier<StatsViewModel> {
  late GameStatsRepository _repository;

  @override
  Future<StatsViewModel> build() async {
    _repository = ref.watch(statsRepositoryProvider);

    // Initialiser le repository si pas encore fait
    try {
      await _repository.initialize();
    } catch (e) {
      // Repository déjà initialisé
    }

    return _loadStats();
  }

  /// Charge les statistiques selon les filtres actuels
  Future<StatsViewModel> _loadStats() async {
    final filter = ref.read(statsFilterProvider);

    try {
      // Récupérer les sessions selon les filtres
      final allSessions = await _repository.query(
        from: filter.range.startDate,
        drawMode: filter.drawMode,
      );

      // Sessions récentes (20 dernières)
      final recentSessions = await _repository.query(
        limit: 20,
      );

      // Calcul des stats agrégées sur les sessions filtrées
      final aggregatedStats =
          await _repository.computeAggregatedStats(allSessions);

      // Tendances sur 7 et 30 jours (toutes sessions, pas filtrées par drawMode)
      final allSessionsForTrends = await _repository.query();
      final trend7 = _repository.generateTrendPoints(allSessionsForTrends, 7);
      final trend30 = _repository.generateTrendPoints(allSessionsForTrends, 30);

      return StatsViewModel(
        games: aggregatedStats.games,
        wins: aggregatedStats.wins,
        winRate: aggregatedStats.winRate,
        bestTime: aggregatedStats.bestTime,
        avgTime: aggregatedStats.avgTime,
        avgMoves: aggregatedStats.avgMoves,
        scoreStandardSum: aggregatedStats.scoreStandardSum,
        vegasBankroll: aggregatedStats.vegasBankroll,
        currentStreak: aggregatedStats.currentStreak,
        bestStreak: aggregatedStats.bestStreak,
        trend7: trend7,
        trend30: trend30,
        recent: recentSessions,
      );
    } catch (e) {
      // En cas d'erreur, retourner un ViewModel vide
      return StatsViewModel.empty();
    }
  }

  /// Change la période de filtrage
  Future<void> setRange(StatsRange range) async {
    final currentFilter = ref.read(statsFilterProvider);
    if (currentFilter.range != range) {
      ref.read(statsFilterProvider.notifier).state =
          currentFilter.copyWith(range: range);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(_loadStats);
    }
  }

  /// Change le mode de pioche pour le filtrage
  Future<void> setDrawMode(DrawMode? drawMode) async {
    final currentFilter = ref.read(statsFilterProvider);
    if (currentFilter.drawMode != drawMode) {
      ref.read(statsFilterProvider.notifier).state =
          currentFilter.copyWith(drawMode: drawMode);
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(_loadStats);
    }
  }

  /// Recharge les statistiques
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadStats);
  }

  /// Ajoute une session de jeu et rafraîchit les stats
  Future<void> addGameSession(GameSession session) async {
    await _repository.addSession(session);
    await refresh();
  }
}

/// Provider pour le contrôleur des statistiques
final statsControllerProvider =
    AsyncNotifierProvider<StatsController, StatsViewModel>(() {
  return StatsController();
});
