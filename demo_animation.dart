// Script de démonstration de l'animation de distribution
// Pour tester manuellement l'API

import 'package:solitaire_klondike/features/solitaire/domain/services/dealer.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';

void main() {
  print("=== Démonstration de l'animation de distribution ===\n");

  const dealer = Dealer();
  const seed = 12345;
  const mode = DrawMode.one;

  // 1. Générer le plan de distribution
  print('1. Génération du plan de distribution...');
  final plan = dealer.dealPlan(seed, mode);

  print('   ✓ Plan généré avec ${plan.steps.length} étapes');
  print('   ✓ ${plan.remainingCards.length} cartes restantes pour le stock');
  print('   ✓ Seed: ${plan.seed}');
  print('   ✓ Mode: ${plan.drawMode}');
  print('   ✓ Plan valide: ${plan.isValid}\n');

  // 2. Afficher la séquence de distribution
  print('2. Séquence de distribution (5 premières étapes):');
  for (var i = 0; i < 5 && i < plan.steps.length; i++) {
    final step = plan.steps[i];
    final flipIcon = step.isLastInColumn ? ' 🔄' : '';
    print(
        '   Étape ${i + 1}: ${step.card.rank}${step.card.suit} → Colonne ${step.column}$flipIcon');
  }
  if (plan.steps.length > 5) {
    print('   ... (${plan.steps.length - 5} étapes restantes)');
  }
  print('');

  // 3. Vérifier la distribution finale
  print('3. Répartition finale des cartes:');
  final cardsPerColumn = List.filled(7, 0);
  final flipCardsPerColumn = List.filled(7, 0);

  for (final step in plan.steps) {
    cardsPerColumn[step.column]++;
    if (step.isLastInColumn) flipCardsPerColumn[step.column]++;
  }

  for (var i = 0; i < 7; i++) {
    print(
        '   Colonne $i: ${cardsPerColumn[i]} cartes (${flipCardsPerColumn[i]} face up)');
  }
  print('');

  // 4. Comparer avec la distribution classique
  print('4. Comparaison avec distribution classique:');
  final classicState = dealer.deal(seed, mode);

  var identical = true;
  for (var i = 0; i < 7; i++) {
    final expectedCount = classicState.tableau[i].length;
    if (cardsPerColumn[i] != expectedCount) {
      identical = false;
      print(
          '   ❌ Colonne $i: attendu $expectedCount, obtenu ${cardsPerColumn[i]}');
    }
  }

  if (identical) {
    print('   ✓ Distribution identique à la méthode classique');
  }

  final expectedStock = classicState.stock.length;
  if (plan.remainingCards.length == expectedStock) {
    print('   ✓ Stock identique: ${plan.remainingCards.length} cartes');
  } else {
    print(
        '   ❌ Stock différent: attendu $expectedStock, obtenu ${plan.remainingCards.length}');
  }

  print('\n=== Démonstration terminée ===');
}
