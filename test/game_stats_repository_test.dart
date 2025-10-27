import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_stats_repository.dart';

void main() {
  group('GameStatsRepository Tests', () {
    late GameStatsRepository repository;

    setUpAll(() async {
      // Initialiser Hive pour les tests
      await Hive.initFlutter();

      // Nettoyer les boîtes de tests s'il y en a
      try {
        await Hive.deleteBoxFromDisk('test_game_sessions');
        await Hive.deleteBoxFromDisk('test_stats_totals');
      } catch (e) {
        // Ignorer si les boîtes n'existent pas
      }
    });

    setUp(() async {
      repository = GameStatsRepository();
      // Changer les noms de boîtes pour les tests
      repository = TestGameStatsRepository();
      await repository.initialize();
    });

    tearDown(() async {
      await repository.clearAll();
      await repository.close();
    });

    group('addSession', () {
      test('ajoute une session et met à jour les totaux correctement',
          () async {
        final session = GameSession(
          id: 'test_1',
          seed: 12345,
          drawMode: DrawMode.draw1,
          won: true,
          moves: 150,
          elapsedMs: 180000, // 3 minutes
          scoreStandard: 5000,
          scoreVegas: 100,
          startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
          endedAt: DateTime.now(),
        );

        await repository.addSession(session);

        final totals = await repository.getTotals();
        expect(totals.games, equals(1));
        expect(totals.wins, equals(1));
        expect(totals.winRate, equals(1.0));
        expect(totals.currentWinStreak, equals(1));
        expect(totals.bestWinStreak, equals(1));
        expect(totals.bestTimeMs, equals(180000));
        expect(totals.bestMoves, equals(150));
        expect(totals.vegasBankroll, equals(100));
      });

      test(
          'calcule correctement les streaks avec alternance de victoires/défaites',
          () async {
        final sessions = [
          // Victoire
          GameSession(
            id: 'test_1',
            seed: 1,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 100,
            elapsedMs: 120000,
            scoreStandard: 1000,
            scoreVegas: 50,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
          // Victoire
          GameSession(
            id: 'test_2',
            seed: 2,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 110,
            elapsedMs: 130000,
            scoreStandard: 1100,
            scoreVegas: 60,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
          // Défaite (devrait réinitialiser le streak actuel)
          GameSession(
            id: 'test_3',
            seed: 3,
            drawMode: DrawMode.draw1,
            won: false,
            moves: 50,
            elapsedMs: 60000,
            scoreStandard: 0,
            scoreVegas: -10,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
          // Victoire (nouveau streak)
          GameSession(
            id: 'test_4',
            seed: 4,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 95,
            elapsedMs: 110000,
            scoreStandard: 1200,
            scoreVegas: 70,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
        ];

        for (final session in sessions) {
          await repository.addSession(session);
        }

        final totals = await repository.getTotals();
        expect(totals.games, equals(4));
        expect(totals.wins, equals(3));
        expect(totals.winRate, equals(0.75));
        expect(
            totals.currentWinStreak, equals(1)); // Dernier était une victoire
        expect(totals.bestWinStreak, equals(2)); // Meilleur streak était de 2
        expect(totals.bestTimeMs, equals(110000)); // Meilleur temps
        expect(totals.bestMoves, equals(95)); // Moins de coups
      });
    });

    group('query', () {
      test('filtre correctement par période', () async {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final lastWeek = now.subtract(const Duration(days: 8));

        final sessions = [
          GameSession(
            id: 'recent',
            seed: 1,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 100,
            elapsedMs: 120000,
            scoreStandard: 1000,
            scoreVegas: 0,
            startedAt: now,
            endedAt: now,
          ),
          GameSession(
            id: 'yesterday',
            seed: 2,
            drawMode: DrawMode.draw1,
            won: false,
            moves: 200,
            elapsedMs: 240000,
            scoreStandard: 0,
            scoreVegas: 0,
            startedAt: yesterday,
            endedAt: yesterday,
          ),
          GameSession(
            id: 'old',
            seed: 3,
            drawMode: DrawMode.draw3,
            won: true,
            moves: 150,
            elapsedMs: 180000,
            scoreStandard: 2000,
            scoreVegas: 0,
            startedAt: lastWeek,
            endedAt: lastWeek,
          ),
        ];

        for (final session in sessions) {
          await repository.addSession(session);
        }

        // Test filtre par date récente (depuis hier)
        final recentSessions = await repository.query(
          from: yesterday.subtract(const Duration(hours: 1)),
        );
        expect(recentSessions.length, equals(2));
        expect(recentSessions.map((s) => s.id),
            containsAll(['recent', 'yesterday']));

        // Test filtre par mode de pioche
        final draw3Sessions = await repository.query(drawMode: DrawMode.draw3);
        expect(draw3Sessions.length, equals(1));
        expect(draw3Sessions.first.id, equals('old'));
      });

      test('limite correctement le nombre de résultats', () async {
        // Ajouter 5 sessions
        for (var i = 0; i < 5; i++) {
          await repository.addSession(
            GameSession(
              id: 'test_$i',
              seed: i,
              drawMode: DrawMode.draw1,
              won: i % 2 == 0,
              moves: 100 + i,
              elapsedMs: 120000 + i * 1000,
              scoreStandard: 1000 * i,
              scoreVegas: 0,
              startedAt: DateTime.now().subtract(Duration(minutes: i)),
              endedAt: DateTime.now().subtract(Duration(minutes: i)),
            ),
          );
        }

        final limitedSessions = await repository.query(limit: 3);
        expect(limitedSessions.length, equals(3));
        // Vérifier que c'est trié par date décroissante
        expect(limitedSessions.first.id, equals('test_0')); // Plus récent
      });
    });

    group('computeAggregatedStats', () {
      test('calcule correctement les statistiques agrégées', () async {
        final sessions = [
          GameSession(
            id: 'win1',
            seed: 1,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 100,
            elapsedMs: 120000, // 2 minutes
            scoreStandard: 1000,
            scoreVegas: 50,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
          GameSession(
            id: 'win2',
            seed: 2,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 150,
            elapsedMs: 180000, // 3 minutes
            scoreStandard: 1500,
            scoreVegas: 75,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
          GameSession(
            id: 'loss1',
            seed: 3,
            drawMode: DrawMode.draw1,
            won: false,
            moves: 80,
            elapsedMs: 60000, // 1 minute
            scoreStandard: 0,
            scoreVegas: -20,
            startedAt: DateTime.now(),
            endedAt: DateTime.now(),
          ),
        ];

        final stats = await repository.computeAggregatedStats(sessions);

        expect(stats.games, equals(3));
        expect(stats.wins, equals(2));
        expect(stats.winRate, closeTo(0.6667, 0.01));
        expect(stats.avgTime.inMilliseconds,
            equals(120000)); // (120000 + 180000 + 60000) / 3
        expect(stats.avgMoves, closeTo(110.0, 0.1)); // (100 + 150 + 80) / 3
        expect(stats.bestTime.inMilliseconds,
            equals(120000)); // Meilleur temps pour une victoire
        expect(
            stats.bestMoves, equals(100)); // Moins de coups pour une victoire
        expect(stats.vegasBankroll, equals(105)); // 50 + 75 - 20
      });

      test('retourne des stats vides pour une liste vide', () async {
        final stats = await repository.computeAggregatedStats([]);
        expect(stats.games, equals(0));
        expect(stats.wins, equals(0));
        expect(stats.winRate, equals(0.0));
        expect(stats.avgTime, equals(Duration.zero));
        expect(stats.avgMoves, equals(0.0));
      });
    });

    group('generateTrendPoints', () {
      test('génère des points de tendance pour les N derniers jours', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        final sessions = [
          // 2 victoires aujourd'hui
          GameSession(
            id: 'today1',
            seed: 1,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 100,
            elapsedMs: 120000,
            scoreStandard: 1000,
            scoreVegas: 0,
            startedAt: now,
            endedAt: now,
          ),
          GameSession(
            id: 'today2',
            seed: 2,
            drawMode: DrawMode.draw1,
            won: true,
            moves: 110,
            elapsedMs: 130000,
            scoreStandard: 1100,
            scoreVegas: 0,
            startedAt: now,
            endedAt: now,
          ),
          // 1 défaite hier
          GameSession(
            id: 'yesterday1',
            seed: 3,
            drawMode: DrawMode.draw1,
            won: false,
            moves: 50,
            elapsedMs: 60000,
            scoreStandard: 0,
            scoreVegas: 0,
            startedAt: yesterday,
            endedAt: yesterday,
          ),
        ];

        final trend = repository.generateTrendPoints(sessions, 3);

        expect(trend.length, equals(3));

        // Vérifier le point d'aujourd'hui
        final todayPoint = trend.last;
        expect(todayPoint.date, equals(today));
        expect(todayPoint.games, equals(2));
        expect(todayPoint.wins, equals(2));
        expect(todayPoint.winRate, equals(1.0));

        // Vérifier le point d'hier
        final yesterdayPoint = trend[trend.length - 2];
        expect(yesterdayPoint.date, equals(yesterday));
        expect(yesterdayPoint.games, equals(1));
        expect(yesterdayPoint.wins, equals(0));
        expect(yesterdayPoint.winRate, equals(0.0));

        // Vérifier qu'il y a un point pour avant-hier (même sans données)
        final dayBeforePoint = trend.first;
        expect(dayBeforePoint.games, equals(0));
        expect(dayBeforePoint.wins, equals(0));
      });
    });
  });
}

/// Version de test du repository avec des noms de boîtes différents
class TestGameStatsRepository extends GameStatsRepository {
  static const String _testSessionsBoxName = 'test_game_sessions';
  static const String _testTotalsBoxName = 'test_stats_totals';
  static const String _testTotalsKey = 'test_overall';

  Box<GameSession>? _testSessionsBox;
  Box<StatsTotals>? _testTotalsBox;

  @override
  Future<void> initialize() async {
    _testSessionsBox = await Hive.openBox<GameSession>(_testSessionsBoxName);
    _testTotalsBox = await Hive.openBox<StatsTotals>(_testTotalsBoxName);
  }

  @override
  Future<void> addSession(GameSession session) async {
    if (_testSessionsBox == null || _testTotalsBox == null) {
      throw Exception('Test repository not initialized');
    }

    await _testSessionsBox!.put(session.id, session);

    var totals = _testTotalsBox!.get(_testTotalsKey) ?? StatsTotals();
    totals = _updateTotals(totals, session);
    await _testTotalsBox!.put(_testTotalsKey, totals);
  }

  @override
  Future<List<GameSession>> query({
    DateTime? from,
    DateTime? to,
    DrawMode? drawMode,
    int? limit,
  }) async {
    if (_testSessionsBox == null) {
      throw Exception('Test repository not initialized');
    }

    var sessions = _testSessionsBox!.values.toList();

    if (from != null) {
      sessions = sessions.where((s) => s.endedAt.isAfter(from)).toList();
    }
    if (to != null) {
      sessions = sessions.where((s) => s.endedAt.isBefore(to)).toList();
    }
    if (drawMode != null) {
      sessions = sessions.where((s) => s.drawMode == drawMode).toList();
    }

    sessions.sort((a, b) => b.endedAt.compareTo(a.endedAt));

    if (limit != null && sessions.length > limit) {
      sessions = sessions.take(limit).toList();
    }

    return sessions;
  }

  @override
  Future<StatsTotals> getTotals() async {
    if (_testTotalsBox == null) {
      throw Exception('Test repository not initialized');
    }
    return _testTotalsBox!.get(_testTotalsKey) ?? StatsTotals();
  }

  @override
  Future<void> clearAll() async {
    await _testSessionsBox?.clear();
    await _testTotalsBox?.clear();
  }

  @override
  Future<void> close() async {
    await _testSessionsBox?.close();
    await _testTotalsBox?.close();
    _testSessionsBox = null;
    _testTotalsBox = null;
  }

  // Méthode helper réutilisée de la classe parent
  StatsTotals _updateTotals(StatsTotals totals, GameSession session) {
    totals.games++;
    totals.sumMoves += session.moves;
    totals.sumElapsedMs += session.elapsedMs;
    totals.vegasBankroll += session.scoreVegas;

    if (session.won) {
      totals.wins++;
      totals.currentWinStreak++;

      if (totals.currentWinStreak > totals.bestWinStreak) {
        totals.bestWinStreak = totals.currentWinStreak;
      }

      if (totals.bestTimeMs == 0 || session.elapsedMs < totals.bestTimeMs) {
        totals.bestTimeMs = session.elapsedMs;
      }

      if (totals.bestMoves == 0 || session.moves < totals.bestMoves) {
        totals.bestMoves = session.moves;
      }
    } else {
      totals.currentWinStreak = 0;
    }

    return totals;
  }
}
