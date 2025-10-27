import 'dart:io';
import 'package:hive/hive.dart';
import 'package:solitaire_klondike/features/solitaire/data/hive_adapters.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart'
    as stats;
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_stats_repository.dart';

/// Test simple console pour les statistiques
void main() async {
  print('=== Test du système de statistiques (Console) ===');

  try {
    // Initialiser Hive avec un répertoire temporaire
    final dir = Directory.systemTemp.createTempSync('solitaire_test');
    Hive.init(dir.path);

    // Enregistrer les adaptateurs
    registerHiveAdapters();

    // Créer le dépôt de statistiques
    final statsRepo = GameStatsRepository();
    await statsRepo.initialize();

    // Créer quelques sessions de test
    await _createTestSessions(statsRepo);

    // Tester l'agrégation
    await _testAggregation(statsRepo);

    // Tester les requêtes
    await _testQueries(statsRepo);

    print('\n✅ Tous les tests sont passés avec succès !');
  } catch (e, stackTrace) {
    print('\n❌ Erreur : $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Nettoyer
    await Hive.close();
  }
}

Future<void> _createTestSessions(GameStatsRepository repo) async {
  print('\n📊 Création de sessions de test...');

  final now = DateTime.now();

  // Session gagnée récente (pioche 1 carte)
  await repo.addSession(
    stats.GameSession(
      id: '1',
      seed: 12345,
      drawMode: stats.DrawMode.draw1,
      won: true,
      moves: 125,
      elapsedMs: const Duration(minutes: 8, seconds: 45).inMilliseconds,
      scoreStandard: 1250,
      scoreVegas: 52,
      startedAt:
          now.subtract(const Duration(hours: 2, minutes: 8, seconds: 45)),
      endedAt: now.subtract(const Duration(hours: 2)),
    ),
  );

  // Session perdue récente (pioche 3 cartes)
  await repo.addSession(
    stats.GameSession(
      id: '2',
      seed: 67890,
      drawMode: stats.DrawMode.draw3,
      won: false,
      moves: 87,
      elapsedMs: const Duration(minutes: 12, seconds: 20).inMilliseconds,
      scoreStandard: 680,
      scoreVegas: -52,
      startedAt:
          now.subtract(const Duration(hours: 6, minutes: 12, seconds: 20)),
      endedAt: now.subtract(const Duration(hours: 6)),
    ),
  );

  // Session gagnée ancienne (pioche 1 carte)
  await repo.addSession(
    stats.GameSession(
      id: '3',
      seed: 11111,
      drawMode: stats.DrawMode.draw1,
      won: true,
      moves: 98,
      elapsedMs: const Duration(minutes: 6, seconds: 15).inMilliseconds,
      scoreStandard: 1580,
      scoreVegas: 104,
      startedAt: now.subtract(const Duration(days: 5, minutes: 6, seconds: 15)),
      endedAt: now.subtract(const Duration(days: 5)),
    ),
  );

  print('✓ 3 sessions de test créées');
}

Future<void> _testAggregation(GameStatsRepository repo) async {
  print("\n🔢 Test de l'agrégation...");

  final totals = await repo.getTotals();

  print('  - Nombre de parties: ${totals.games}');
  print('  - Parties gagnées: ${totals.wins}');
  print('  - Taux de victoire: ${(totals.winRate * 100).toStringAsFixed(1)}%');
  print(
      '  - Temps moyen: ${totals.avgTime.inMinutes}m ${totals.avgTime.inSeconds % 60}s');
  print('  - Mouvements moyens: ${totals.avgMoves.toStringAsFixed(1)}');

  assert(totals.games == 3, 'Devrait y avoir 3 parties');
  assert(totals.wins == 2, 'Devrait y avoir 2 parties gagnées');
  assert((totals.winRate - 2 / 3).abs() < 0.01, 'Taux de victoire incorrect');

  print('✓ Agrégation correcte');
}

Future<void> _testQueries(GameStatsRepository repo) async {
  print('\n🔍 Test des requêtes...');

  // Filtre par mode de pioche
  final drawOneSessions = await repo.query(drawMode: stats.DrawMode.draw1);

  print('  - Sessions en mode 1 carte: ${drawOneSessions.length}');
  assert(drawOneSessions.length == 2,
      'Devrait y avoir 2 sessions en mode 1 carte');

  // Filtre par période (sessions récentes)
  final now = DateTime.now();
  final todaySessions = await repo.query(
    from: DateTime(now.year, now.month, now.day),
  );

  print("  - Sessions aujourd'hui: ${todaySessions.length}");
  assert(todaySessions.length == 2, "Devrait y avoir 2 sessions aujourd'hui");

  // Test avec limite
  final limitedSessions = await repo.query(limit: 2);
  print('  - Sessions avec limite 2: ${limitedSessions.length}');
  assert(limitedSessions.length == 2, 'Devrait être limité à 2 sessions');

  print('✓ Requêtes fonctionnelles');
}
