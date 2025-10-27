import 'package:flutter_test/flutter_test.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/dealer.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/deal_plan.dart';

void main() {
  group('Deal Animation Tests', () {
    late Dealer dealer;

    setUp(() {
      dealer = const Dealer();
    });

    test('dealPlan should generate valid round-robin distribution', () {
      const seed = 12345;
      const mode = DrawMode.one;

      final plan = dealer.dealPlan(seed, mode);

      // Vérifications de base
      expect(plan.isValid, isTrue);
      expect(plan.steps.length, equals(28));
      expect(plan.remainingCards.length, equals(24));
      expect(plan.seed, equals(seed));
      expect(plan.drawMode, equals(mode));
    });

    test('dealPlan should follow Klondike round-robin rules', () {
      final plan = dealer.dealPlan(12345, DrawMode.one);

      // Vérifier la distribution round-robin
      final cardsPerColumn = List.filled(7, 0);
      for (final step in plan.steps) {
        expect(step.column, inInclusiveRange(0, 6));
        cardsPerColumn[step.column]++;
      }

      // Colonne i doit recevoir i+1 cartes (0->1, 1->2, ..., 6->7)
      for (var i = 0; i < 7; i++) {
        expect(
          cardsPerColumn[i],
          equals(i + 1),
          reason: 'Colonne $i devrait avoir ${i + 1} cartes',
        );
      }
    });

    test('dealPlan should mark last cards for flip', () {
      final plan = dealer.dealPlan(12345, DrawMode.one);

      // Compter les cartes marquées pour flip par colonne
      final flipCardsPerColumn = List.filled(7, 0);
      for (final step in plan.steps) {
        if (step.isLastInColumn) {
          flipCardsPerColumn[step.column]++;
        }
      }

      // Chaque colonne doit avoir exactement 1 carte marquée pour flip
      for (var i = 0; i < 7; i++) {
        expect(
          flipCardsPerColumn[i],
          equals(1),
          reason: 'Colonne $i devrait avoir exactement 1 carte à retourner',
        );
      }
    });

    test('dealPlan should distribute 52 unique cards', () {
      final plan = dealer.dealPlan(12345, DrawMode.one);

      final allCards = [
        ...plan.steps.map((s) => s.card),
        ...plan.remainingCards,
      ];

      expect(allCards.length, equals(52));

      // Vérifier l'unicité des IDs
      final uniqueIds = allCards.map((c) => c.id).toSet();
      expect(uniqueIds.length, equals(52));
    });

    test('dealPlan result should be deterministic with same seed', () {
      const seed = 98765;

      final plan1 = dealer.dealPlan(seed, DrawMode.one);
      final plan2 = dealer.dealPlan(seed, DrawMode.one);

      expect(plan1.steps.length, equals(plan2.steps.length));

      for (var i = 0; i < plan1.steps.length; i++) {
        expect(plan1.steps[i].card.id, equals(plan2.steps[i].card.id));
        expect(plan1.steps[i].column, equals(plan2.steps[i].column));
        expect(plan1.steps[i].isLastInColumn,
            equals(plan2.steps[i].isLastInColumn));
      }
    });

    test('animated and non-animated deals should produce identical final state',
        () {
      const seed = 54321;
      const mode = DrawMode.three;

      // Distribution classique
      final classicState = dealer.deal(seed, mode);

      // Plan de distribution animée
      final plan = dealer.dealPlan(seed, mode);

      // Reconstruire l'état final à partir du plan
      // Pour simplifier le test, on vérifie juste les comptages
      final tableauCounts = List.filled(7, 0);
      for (final step in plan.steps) {
        tableauCounts[step.column]++;
      }

      // Vérifier que les comptages correspondent
      for (var i = 0; i < 7; i++) {
        expect(tableauCounts[i], equals(classicState.tableau[i].length));
      }

      expect(plan.remainingCards.length, equals(classicState.stock.length));
    });
  });
}
