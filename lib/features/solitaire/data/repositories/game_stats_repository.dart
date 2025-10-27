import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';

/// Repository pour la gestion des statistiques de jeu
class GameStatsRepository {
  static const String _sessionsBoxName = 'game_sessions';
  static const String _totalsBoxName = 'stats_totals';
  static const String _totalsKey = 'overall';

  Box<GameSession>? _sessionsBox;
  Box<StatsTotals>? _totalsBox;

  /// Initialise les boîtes Hive
  Future<void> initialize() async {
    _sessionsBox = await Hive.openBox<GameSession>(_sessionsBoxName);
    _totalsBox = await Hive.openBox<StatsTotals>(_totalsBoxName);
  }

  /// Ajoute une session de jeu et met à jour les totaux atomiquement
  Future<void> addSession(GameSession session) async {
    if (_sessionsBox == null || _totalsBox == null) {
      throw Exception('Repository not initialized');
    }

    // Ajouter la session
    await _sessionsBox!.put(session.id, session);

    // Mettre à jour les totaux
    var totals = _totalsBox!.get(_totalsKey) ?? StatsTotals();
    totals = _updateTotals(totals, session);
    await _totalsBox!.put(_totalsKey, totals);
  }

  /// Met à jour les totaux avec une nouvelle session
  StatsTotals _updateTotals(StatsTotals totals, GameSession session) {
    // Mettre à jour les compteurs de base
    totals.games++;
    totals.sumMoves += session.moves;
    totals.sumElapsedMs += session.elapsedMs;

    // Vegas bankroll
    totals.vegasBankroll += session.scoreVegas;

    if (session.won) {
      totals.wins++;
      totals.currentWinStreak++;

      // Meilleur streak
      if (totals.currentWinStreak > totals.bestWinStreak) {
        totals.bestWinStreak = totals.currentWinStreak;
      }

      // Meilleur temps (si c'est le premier win ou si c'est mieux)
      if (totals.bestTimeMs == 0 || session.elapsedMs < totals.bestTimeMs) {
        totals.bestTimeMs = session.elapsedMs;
      }

      // Meilleur nombre de coups
      if (totals.bestMoves == 0 || session.moves < totals.bestMoves) {
        totals.bestMoves = session.moves;
      }
    } else {
      // Réinitialiser le streak si perdu
      totals.currentWinStreak = 0;
    }

    return totals;
  }

  /// Récupère les sessions avec filtres optionnels
  Future<List<GameSession>> query({
    DateTime? from,
    DateTime? to,
    DrawMode? drawMode,
    int? limit,
  }) async {
    if (_sessionsBox == null) {
      throw Exception('Repository not initialized');
    }

    var sessions = _sessionsBox!.values.toList();

    // Filtres
    if (from != null) {
      sessions = sessions.where((s) => s.endedAt.isAfter(from)).toList();
    }
    if (to != null) {
      sessions = sessions.where((s) => s.endedAt.isBefore(to)).toList();
    }
    if (drawMode != null) {
      sessions = sessions.where((s) => s.drawMode == drawMode).toList();
    }

    // Trier par date de fin décroissante
    sessions.sort((a, b) => b.endedAt.compareTo(a.endedAt));

    // Limiter si demandé
    if (limit != null && sessions.length > limit) {
      sessions = sessions.take(limit).toList();
    }

    return sessions;
  }

  /// Récupère les totaux globaux
  Future<StatsTotals> getTotals() async {
    if (_totalsBox == null) {
      throw Exception('Repository not initialized');
    }
    return _totalsBox!.get(_totalsKey) ?? StatsTotals();
  }

  /// Calcule les statistiques agrégées pour une liste de sessions
  /// Utilise compute pour éviter de bloquer l'UI sur de gros datasets
  Future<AggregatedStats> computeAggregatedStats(
      List<GameSession> sessions) async {
    if (sessions.isEmpty) {
      return AggregatedStats.empty();
    }

    // Si peu de sessions, calcul direct
    if (sessions.length <= 100) {
      return _computeStatsSync(sessions);
    }

    // Sinon, utiliser compute
    return compute(_computeStatsSync, sessions);
  }

  /// Calcul synchrone des statistiques (pour compute)
  static AggregatedStats _computeStatsSync(List<GameSession> sessions) {
    if (sessions.isEmpty) return AggregatedStats.empty();

    final wins = sessions.where((s) => s.won).toList();
    final winCount = wins.length;
    final totalGames = sessions.length;

    var bestTimeMs = 0;
    var bestMoves = 0;
    var totalElapsedMs = 0;
    var totalMoves = 0;
    var totalScoreStandard = 0;
    var totalScoreVegas = 0;

    for (final session in sessions) {
      totalElapsedMs += session.elapsedMs;
      totalMoves += session.moves;
      totalScoreStandard += session.scoreStandard;
      totalScoreVegas += session.scoreVegas;

      if (session.won) {
        if (bestTimeMs == 0 || session.elapsedMs < bestTimeMs) {
          bestTimeMs = session.elapsedMs;
        }
        if (bestMoves == 0 || session.moves < bestMoves) {
          bestMoves = session.moves;
        }
      }
    }

    // Calcul du streak actuel
    var currentStreak = 0;
    for (var i = 0; i < sessions.length; i++) {
      if (sessions[i].won) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calcul du meilleur streak
    var bestStreak = 0;
    var tempStreak = 0;
    for (final session in sessions.reversed) {
      if (session.won) {
        tempStreak++;
        bestStreak = max(bestStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }

    return AggregatedStats(
      games: totalGames,
      wins: winCount,
      winRate: winCount / totalGames,
      avgTime: Duration(milliseconds: totalElapsedMs ~/ totalGames),
      avgMoves: totalMoves / totalGames,
      bestTime:
          bestTimeMs > 0 ? Duration(milliseconds: bestTimeMs) : Duration.zero,
      bestMoves: bestMoves,
      scoreStandardSum: totalScoreStandard,
      vegasBankroll: totalScoreVegas,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  /// Génère les points de tendance pour les N derniers jours
  List<TimePoint> generateTrendPoints(List<GameSession> sessions, int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));

    // Créer une map pour grouper par jour
    final sessionsByDay = <DateTime, List<GameSession>>{};

    for (final session in sessions) {
      if (session.endedAt
          .isAfter(startDate.subtract(const Duration(days: 1)))) {
        final day = DateTime(
          session.endedAt.year,
          session.endedAt.month,
          session.endedAt.day,
        );
        sessionsByDay.putIfAbsent(day, () => []).add(session);
      }
    }

    // Générer les points pour chaque jour
    final points = <TimePoint>[];
    for (var i = days - 1; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final daySessions = sessionsByDay[day] ?? <GameSession>[];
      final wins = daySessions.where((s) => s.won).length;

      points.add(
        TimePoint(
          date: day,
          wins: wins,
          games: daySessions.length,
        ),
      );
    }

    return points;
  }

  /// Efface toutes les statistiques (pour debug/reset)
  Future<void> clearAll() async {
    if (_sessionsBox != null) {
      await _sessionsBox!.clear();
    }
    if (_totalsBox != null) {
      await _totalsBox!.clear();
    }
  }

  /// Ferme les boîtes
  Future<void> close() async {
    await _sessionsBox?.close();
    await _totalsBox?.close();
    _sessionsBox = null;
    _totalsBox = null;
  }
}

/// Statistiques agrégées calculées
class AggregatedStats {
  const AggregatedStats({
    required this.games,
    required this.wins,
    required this.winRate,
    required this.avgTime,
    required this.avgMoves,
    required this.bestTime,
    required this.bestMoves,
    required this.scoreStandardSum,
    required this.vegasBankroll,
    required this.currentStreak,
    required this.bestStreak,
  });

  factory AggregatedStats.empty() => const AggregatedStats(
        games: 0,
        wins: 0,
        winRate: 0,
        avgTime: Duration.zero,
        avgMoves: 0,
        bestTime: Duration.zero,
        bestMoves: 0,
        scoreStandardSum: 0,
        vegasBankroll: 0,
        currentStreak: 0,
        bestStreak: 0,
      );
  final int games;
  final int wins;
  final double winRate;
  final Duration avgTime;
  final double avgMoves;
  final Duration bestTime;
  final int bestMoves;
  final int scoreStandardSum;
  final int vegasBankroll;
  final int currentStreak;
  final int bestStreak;

  @override
  String toString() =>
      'AggregatedStats(games: $games, wins: $wins, winRate: ${(winRate * 100).toStringAsFixed(1)}%)';
}
