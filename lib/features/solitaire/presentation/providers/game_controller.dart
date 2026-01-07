import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/deal_plan.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_result.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/dealer.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/klondike_rules.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/scorer_service.dart';
import 'package:solitaire_klondike/features/solitaire/domain/services/hint_engine.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_repository.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_stats_repository.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart'
    as stats;
import 'package:solitaire_klondike/core/utils/settings_service.dart';

/// Provider pour le service dealer
final dealerProvider = Provider<Dealer>((ref) => const Dealer());

/// Provider pour les règles du jeu
final klondikeRulesProvider =
    Provider<KlondikeRules>((ref) => const KlondikeRules());

/// Provider pour le service de score
final scorerServiceProvider =
    Provider<ScorerService>((ref) => const ScorerService());

/// Provider pour le moteur d'indices
final hintEngineProvider = Provider<HintEngine>((ref) {
  final rules = ref.watch(klondikeRulesProvider);
  return HintEngine(rules: rules);
});

/// Provider pour le repository de statistiques
final gameStatsRepositoryProvider = Provider<GameStatsRepository>((ref) {
  return GameStatsRepository();
});

/// Contrôleur principal du jeu avec état et logique métier
class GameController extends StateNotifier<GameState> {
  GameController(this._repo, this._statsRepo)
      : super(GameState.initial(seed: _generateSeed())) {
    _initializeTimer();
    _tryLoadSavedGame();
    _initializeStatsRepo();
  }

  final GameRepository _repo;
  final GameStatsRepository _statsRepo;
  Timer? _gameTimer;
  DateTime? _gameStartTime;
  bool _uiLocked = false;
  DealtPlan? _pendingDealPlan;
  Completer<void>? _victoryCompleter;

  Dealer get _dealer => const Dealer();
  KlondikeRules get _rules => const KlondikeRules();
  ScorerService get _scorer => const ScorerService();
  HintEngine get _hintEngine => HintEngine(rules: _rules);

  /// Tente de charger une partie sauvegardée au démarrage
  void _tryLoadSavedGame() {
    try {
      final savedGame = _repo.loadGame();
      if (savedGame != null) {
        state = savedGame;
        _initializeTimer();
      }
    } catch (e) {
      // En cas d'erreur, rester sur l'état initial
      print('Erreur lors du chargement de la partie sauvegardée: $e');
    }
  }

  /// Sauvegarde automatique de l'état du jeu
  Future<void> _autoSave() async {
    try {
      // Ne sauvegarder que si le jeu est en cours ou terminé
      if (state.status == GameStatus.playing ||
          state.status == GameStatus.won) {
        await _repo.saveGame(state);
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde automatique: $e');
    }
  }

  static int _generateSeed() => DateTime.now().millisecondsSinceEpoch;

  void _initializeTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == GameStatus.playing && _gameStartTime != null) {
        final elapsed = DateTime.now().difference(_gameStartTime!);
        state = state.updateTime(elapsed);
      }
    });
  }

  /// Initialise le repository de statistiques
  Future<void> _initializeStatsRepo() async {
    try {
      await _statsRepo.initialize();
    } catch (e) {
      debugLog(
        "Erreur lors de l'initialisation du repository de statistiques: $e",
      );
    }
  }

  /// Sauvegarde une session de jeu dans les statistiques
  Future<void> _saveGameSession({
    required bool won,
    bool aborted = false,
  }) async {
    try {
      final now = DateTime.now();
      final gameStart = _gameStartTime ?? now;
      final elapsedMs = now.difference(gameStart).inMilliseconds;

      // Convertir le DrawMode du jeu vers celui des stats
      final statsDrawMode = state.drawMode == DrawMode.one
          ? stats.DrawMode.draw1
          : stats.DrawMode.draw3;

      // Calculer le score Vegas (delta par rapport au score initial)
      final vegasScore = state.scoringMode == ScoringMode.vegas
          ? state.score + 52 // On avait enlevé 52 au début
          : 0;

      final session = stats.GameSession(
        id: '${state.seed}_${now.millisecondsSinceEpoch}',
        seed: state.seed,
        drawMode: statsDrawMode,
        won: won,
        moves: state.moves,
        elapsedMs: elapsedMs,
        scoreStandard:
            state.scoringMode == ScoringMode.standard ? state.score : 0,
        scoreVegas: vegasScore,
        startedAt: gameStart,
        endedAt: now,
        aborted: aborted,
      );

      await _statsRepo.addSession(session);
      debugLog(
        'Session de jeu sauvegardée: ${won ? 'Victoire' : 'Défaite'} en ${elapsedMs}ms',
      );
    } catch (e) {
      debugLog('Erreur lors de la sauvegarde des statistiques: $e');
    }
  }

  /// Vérifie si la partie est gagnée et déclenche la victoire si c'est le cas
  void _checkVictory() {
    if (state.gameOver) return; // Déjà terminé

    if (_rules.isWin(state)) {
      _onVictory();
    }
  }

  /// Gère la victoire de la partie
  Future<void> _onVictory() async {
    // Arrêter le timer
    _gameTimer?.cancel();

    // Marquer la partie comme terminée avec victoire
    state = state.copyWith(
      gameOver: true,
      gameResult: GameResult.win,
      status: GameStatus.won,
    );

    // Verrouiller l'UI
    setUiLocked(true);

    // Notifier l'UI via le completer (pour déclencher l'overlay)
    _victoryCompleter ??= Completer<void>();
    if (!_victoryCompleter!.isCompleted) {
      _victoryCompleter!.complete();
    }

    // Sauvegarder la session comme gagnée
    await _saveGameSession(won: true);

    // TODO: Haptics/sound optionnels
    // _feedback.victory();

    debugLog(
      'Victoire détectée ! Partie terminée en ${state.time.inSeconds}s avec ${state.moves} coups.',
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  /// Démarre une nouvelle partie avec support d'animation
  Future<void> newGame({
    int? seed,
    DrawMode drawMode = DrawMode.one,
    ScoringMode scoringMode = ScoringMode.standard,
    int? gameNumber,
    bool animated = true,
  }) async {
    final gameSeed = seed ?? _generateSeed();

    // Si une partie était en cours et pas encore terminée, la marquer comme abandonnée
    if (state.status == GameStatus.playing && !_rules.isGameWon(state)) {
      await _saveGameSession(won: false, aborted: true);
    }

    // Réinitialiser le completer de victoire
    _victoryCompleter = null;

    // Nettoyer la sauvegarde précédente
    await _repo.clearSavedGame();

    // Vérifier si les animations doivent être désactivées
    final shouldSkipAnimations = SettingsService.shouldSkipAnimations;
    final effectiveAnimated = animated && !shouldSkipAnimations;

    if (!effectiveAnimated) {
      // Distribution directe sans animation
      final newState = _dealer.deal(gameSeed, drawMode);
      state = newState;
      startTimer();
      debugLog('Nouvelle partie commencée (sans animation) - Seed: $gameSeed');
      return;
    }

    // Distribution animée - préparer le plan
    final plan = _dealer.dealPlan(gameSeed, drawMode);
    _pendingDealPlan = plan;

    // Créer l'état initial avec TOUTES les cartes dans le stock
    // L'animation va les retirer une par une pour les placer dans le tableau
    final allCards = <Card>[];

    // Ajouter toutes les cartes des steps (celles qui iront au tableau)
    for (final step in plan.steps) {
      allCards.add(step.card);
    }

    // Ajouter les cartes restantes (celles qui resteront dans le stock)
    allCards.addAll(plan.remainingCards);

    final initialStock = Pile(type: PileType.stock, cards: allCards);

    state = _createEmptyGameState(gameSeed, drawMode, scoringMode, gameNumber)
        .copyWith(
      status: GameStatus.dealing,
      stock: initialStock,
    );

    debugLog('Nouvelle partie préparée pour animation - Seed: $gameSeed');
    // L'animation sera déclenchée par la GamePage qui détecte le changement d'état
  }

  /// Crée un état de jeu initial vide
  GameState _createEmptyGameState(
    int seed,
    DrawMode drawMode,
    ScoringMode scoringMode,
    int? gameNumber,
  ) {
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
      gameNumber: gameNumber ?? 1,
    );
  }

  /// Ajoute une carte à une colonne du tableau (pour l'animation)
  /// ET la retire du stock pour éviter les duplications
  void commitCardToTableau(Card card, int column, bool faceUp) {
    // 1. Retirer la carte du stock
    final currentStock = List<Card>.from(state.stock.cards);
    final cardIndex = currentStock.indexWhere((c) => c.id == card.id);

    if (cardIndex != -1) {
      currentStock.removeAt(cardIndex);

      // 2. Mettre à jour le stock
      final updatedStock = state.stock.copyWith(cards: currentStock);
      state = state.copyWith(stock: updatedStock);
    }

    // 3. Ajouter la carte au tableau
    _commitCardToTableau(card, column, faceUp);
  }

  /// Retourne la carte du dessus d'une colonne (pour l'animation de flip)
  void flipTableauCard(int columnIndex) {
    _flipTableauCard(columnIndex);
  }

  /// Ajoute une carte à une colonne du tableau (implémentation interne)
  void _commitCardToTableau(Card card, int column, bool faceUp) {
    final currentTableau = List<Pile>.from(state.tableau);
    final targetPile = currentTableau[column];

    // Créer une nouvelle carte au lieu d'utiliser copyWith
    final cardToAdd = Card(
      suit: card.suit,
      rank: card.rank,
      faceUp: faceUp,
      id: card.id, // GARDER le même ID
    );
    final updatedCards = [...targetPile.cards, cardToAdd];
    final updatedPile = targetPile.copyWith(cards: updatedCards);

    currentTableau[column] = updatedPile;

    state = state.copyWith(tableau: currentTableau);
    debugLog(
      'Carte ${card.rank}${card.suit} ajoutée à la colonne $column (faceUp: $faceUp)',
    );
  }

  /// Retourne la carte du dessus d'une colonne (pour l'animation de flip)
  void _flipTableauCard(int columnIndex) {
    final currentTableau = List<Pile>.from(state.tableau);
    final pile = currentTableau[columnIndex];

    if (pile.isNotEmpty && pile.topCard != null && !pile.topCard!.faceUp) {
      // Créer une nouvelle carte retournée au lieu d'utiliser copyWith
      final originalCard = pile.topCard!;
      final flippedCard = Card(
        suit: originalCard.suit,
        rank: originalCard.rank,
        faceUp: true,
        id: originalCard.id, // GARDER le même ID
      );
      final updatedCards = [...pile.cards];
      updatedCards[updatedCards.length - 1] = flippedCard;

      final updatedPile = pile.copyWith(cards: updatedCards);
      currentTableau[columnIndex] = updatedPile;

      state = state.copyWith(tableau: currentTableau);
      debugLog(
        'Carte retournée dans colonne $columnIndex: ${flippedCard.rank}${flippedCard.suit}',
      );
    }
  }

  /// Verrouille/déverrouille l'interface utilisateur
  void setUiLocked(bool locked) {
    _uiLocked = locked;
    debugLog('UI ${locked ? 'verrouillée' : 'déverrouillée'}');
  }

  /// Indique si l'UI est verrouillée
  bool get isUiLocked => _uiLocked;

  /// Récupère le plan de distribution en attente
  DealtPlan? get pendingDealPlan => _pendingDealPlan;

  /// Finalise la distribution après l'animation
  void completeDealAnimation() {
    if (_pendingDealPlan != null) {
      // L'animation a déjà retiré les cartes du stock et les a placées dans le tableau
      // Il ne reste qu'à changer le statut pour indiquer que la partie a commencé
      state = state.copyWith(status: GameStatus.playing);

      _pendingDealPlan = null;
      startTimer();
      debugLog('Animation de distribution terminée');
    }
  }

  /// Version legacy de newGame (sera dépréciée)
  void newGameLegacy({
    int? seed,
    DrawMode drawMode = DrawMode.one,
    ScoringMode scoringMode = ScoringMode.standard,
    int? gameNumber,
  }) {
    final gameSeed = seed ?? _generateSeed();

    state = _dealer.deal(gameSeed, drawMode);

    startTimer();
    debugLog('Nouvelle partie commencée - Seed: $gameSeed');
  }

  /// Démarre le timer de jeu
  void startTimer() {
    _gameStartTime = DateTime.now();
    debugLog('Timer démarré');
  }

  /// Abandonne la partie en cours
  Future<void> quitGame() async {
    if (state.status == GameStatus.playing && !_rules.isGameWon(state)) {
      await _saveGameSession(won: false, aborted: true);
    }
    _gameTimer?.cancel();
  }

  /// Arrête le timer de jeu
  void stopTimer() {
    _gameStartTime = null;
    debugLog('Timer arrêté');
  }

  /// Vérifie s'il y a une partie restaurable
  bool hasRestorableGame() {
    return _repo.hasSavedGame();
  }

  /// Restaure une partie sauvegardée
  void restoreGame() {
    final savedGame = _repo.loadGame();
    if (savedGame != null) {
      state = savedGame;
      startTimer();
      debugLog('Partie restaurée');
    }
  }

  /// Pioche des cartes du stock vers la défausse
  void tapStock() {
    if (state.stock.isEmpty && state.waste.isNotEmpty) {
      // Recycler la défausse vers le stock
      recycleWasteToStock();
    } else if (state.stock.isNotEmpty) {
      // Piocher selon le drawMode
      final cardsToTake = state.drawMode == DrawMode.one ? 1 : 3;
      final actualCardsTaken = cardsToTake.clamp(0, state.stock.length);
      final cardsTaken = state.stock.cards.take(actualCardsTaken).toList();

      final move = Move.stockToWaste(cards: cardsTaken);
      makeMove(move);
    }
  }

  /// Recycle la défausse vers le stock
  void recycleWasteToStock() {
    final move = Move.resetStock(cards: state.waste.cards);
    makeMove(move);
  }

  /// Gère le drop d'une carte sur le tableau
  bool dropCardOnTableau(Card card, int tableauIndex) {
    final move = _createMoveForCardDrop(card, 'tableau', tableauIndex);
    if (move != null) {
      return makeMove(move);
    }
    return false;
  }

  /// Gère le drop d'une carte sur une fondation
  bool dropCardOnFoundation(Card card, int foundationIndex) {
    debugLog(
      '=== dropCardOnFoundation: ${card.rank.symbol}${card.suit.symbol} to foundation $foundationIndex ===',
    );
    final move = _createMoveForCardDrop(card, 'foundation', foundationIndex);
    if (move != null) {
      debugLog('Move created successfully: ${move.from} -> ${move.to}');
      final result = makeMove(move);
      debugLog('makeMove result: $result');
      return result;
    } else {
      debugLog('Failed to create move for foundation drop');
      return false;
    }
  }

  /// Vérifie si une carte peut être droppée sur une pile
  bool canDropCardOn(Card card, String targetType, int targetIndex) {
    // Debug: afficher l'état des fondations si on teste une fondation
    if (targetType == 'foundation') {
      debugLog('--- DEBUG FOUNDATIONS STATE ---');
      for (var i = 0; i < state.foundations.length; i++) {
        final foundation = state.foundations[i];
        if (foundation.isEmpty) {
          debugLog('Foundation $i: EMPTY');
        } else {
          final topCard = foundation.topCard!;
          debugLog(
            'Foundation $i: ${topCard.rank.symbol}${topCard.suit.symbol} (${topCard.suit.name}, ${topCard.rank.value})',
          );
        }
      }
      debugLog(
        '--- Trying to place ${card.rank.symbol}${card.suit.symbol} on foundation $targetIndex ---',
      );
    }

    // D'abord vérifier que ce n'est pas un auto-drop (même source)
    final cardLocation = _findCardLocation(card);
    if (cardLocation != null) {
      final (sourceType, sourceIndex) = cardLocation;
      if (sourceType == targetType && sourceIndex == targetIndex) {
        debugLog(
          'Cannot drop ${card.rank} of ${card.suit} on itself ($targetType $targetIndex)',
        );
        return false;
      }
    }

    final move = _createMoveForCardDrop(card, targetType, targetIndex);
    if (move == null) {
      debugLog(
        'Cannot create move for ${card.rank} of ${card.suit} to $targetType $targetIndex',
      );
      return false;
    }
    final isLegal = _rules.isMoveLegal(move, state);
    debugLog(
      'Move ${card.rank} of ${card.suit} to $targetType $targetIndex: ${isLegal ? 'LEGAL' : 'ILLEGAL'}',
    );
    return isLegal;
  }

  /// Crée un Move pour un drop de carte selon la source et la destination
  Move? _createMoveForCardDrop(Card card, String targetType, int targetIndex) {
    // Trouve la source de la carte
    final cardLocation = _findCardLocation(card);
    if (cardLocation == null) return null;

    final (sourceType, sourceIndex) = cardLocation;

    switch (sourceType) {
      case 'waste':
        if (targetType == 'tableau') {
          return Move.wasteToTableau(card: card, tableauIndex: targetIndex);
        } else if (targetType == 'foundation') {
          return Move.wasteToFoundation(
            card: card,
            foundationIndex: targetIndex,
          );
        }
      case 'tableau':
        if (targetType == 'tableau') {
          // Pour tableau->tableau, nous devons récupérer toutes les cartes à déplacer
          final cardsToMove = _getCardsToMoveFromTableau(sourceIndex!, card);
          return Move.tableauToTableau(
            fromIndex: sourceIndex,
            toIndex: targetIndex,
            cards: cardsToMove,
          );
        } else if (targetType == 'foundation') {
          return Move.tableauToFoundation(
            card: card,
            tableauIndex: sourceIndex!,
            foundationIndex: targetIndex,
          );
        }
      case 'foundation':
        if (targetType == 'tableau') {
          return Move.foundationToTableau(
            card: card,
            foundationIndex: sourceIndex!,
            tableauIndex: targetIndex,
          );
        }
    }
    return null;
  }

  /// Trouve l'emplacement d'une carte dans l'état du jeu
  (String, int?)? _findCardLocation(Card card) {
    // Vérifie la défausse
    if (state.waste.topCard == card) {
      debugLog('Found ${card.rank} of ${card.suit} in waste');
      return ('waste', null);
    }

    // Vérifie les colonnes du tableau
    for (var i = 0; i < state.tableau.length; i++) {
      final pile = state.tableau[i];
      if (pile.cards.contains(card)) {
        debugLog('Found ${card.rank} of ${card.suit} in tableau $i');
        return ('tableau', i);
      }
    }

    // Vérifie les fondations
    for (var i = 0; i < state.foundations.length; i++) {
      final pile = state.foundations[i];
      if (pile.topCard == card) {
        debugLog('Found ${card.rank} of ${card.suit} in foundation $i');
        return ('foundation', i);
      }
    }

    debugLog('Card ${card.rank} of ${card.suit} NOT FOUND in game state!');
    return null;
  }

  /// Récupère toutes les cartes à déplacer depuis un tableau (la carte + celles au-dessus)
  List<Card> _getCardsToMoveFromTableau(int tableauIndex, Card startCard) {
    final pile = state.tableau[tableauIndex];
    final startIndex = pile.cards.indexOf(startCard);
    if (startIndex == -1) return [];

    return pile.cards.sublist(startIndex);
  }

  /// Effectue un mouvement depuis une pile vers une autre (méthode legacy)
  void move(
    String fromType,
    String toType, {
    int? fromIndex,
    int? toIndex,
    int count = 1,
  }) {
    // Cette méthode sera utilisée pour les drag & drop
    // TODO: Implémenter selon les types de piles
    debugLog('Move demandé: $fromType[$fromIndex] -> $toType[$toIndex]');
  }

  /// Logging pour debug
  void debugLog(String message) {
    print('[GameController] $message');
  }

  /// Rejoue la même partie (même distribution)
  void replayGame() {
    state = _dealer.deal(state.seed, state.drawMode);
  }

  /// Change le mode de pioche entre 1 et 3 cartes
  void toggleDrawMode() {
    final newDrawMode =
        state.drawMode == DrawMode.one ? DrawMode.three : DrawMode.one;
    debugLog('Changement de mode de pioche: ${state.drawMode} -> $newDrawMode');
    state = state.copyWith(drawMode: newDrawMode);
  }

  /// Effectue un mouvement s'il est légal
  bool makeMove(Move move) {
    if (!_rules.isMoveLegal(move, state)) {
      return false;
    }

    final newState = _applyMove(move, state);
    final points = _scorer.calculateMoveScore(move, state);

    var finalState = newState.addMoveToHistory(move).addScore(points);

    // Révèle automatiquement les cartes cachées du tableau si nécessaire
    finalState = _autoFlipTableauCards(finalState);

    state = finalState;

    // Validation silencieuse de l'intégrité
    _validateCardIntegrity();

    // Vérifie la victoire après chaque mouvement
    _checkVictory();

    // Sauvegarde automatique après chaque coup
    _autoSave();

    return true;
  }

  /// Révèle automatiquement les cartes cachées du dessus des colonnes du tableau
  GameState _autoFlipTableauCards(GameState gameState) {
    var updatedState = gameState;

    for (var i = 0; i < gameState.tableau.length; i++) {
      final pile = gameState.tableau[i];

      // Si la pile n'est pas vide et que la carte du dessus est face cachée
      if (pile.isNotEmpty && pile.topCard != null && !pile.topCard!.faceUp) {
        // Créer une nouvelle carte retournée au lieu d'utiliser copyWith
        final originalCard = pile.topCard!;
        final flippedCard = Card(
          suit: originalCard.suit,
          rank: originalCard.rank,
          faceUp: true,
          id: originalCard.id, // GARDER le même ID
        );
        final updatedCards = [...pile.cards];
        updatedCards[updatedCards.length - 1] = flippedCard;

        final updatedPile = pile.copyWith(cards: updatedCards);
        updatedState = updatedState.updateTableau(i, updatedPile);

        debugLog(
          'Carte révélée automatiquement dans colonne $i: ${flippedCard.suit} ${flippedCard.rank}',
        );

        // Ajoute un mouvement de retournement à l'historique pour le scoring
        final flipMove =
            Move.flipTableauCard(tableauIndex: i, card: flippedCard);
        updatedState = updatedState.addMoveToHistory(flipMove);
      }
    }

    return updatedState;
  }

  /// Applique un mouvement à l'état du jeu
  GameState _applyMove(Move move, GameState gameState) {
    switch (move.type) {
      case MoveType.stockToWaste:
        return _applyStockToWaste(gameState);

      case MoveType.wasteToTableau:
        return _applyWasteToTableau(move.to!, gameState);

      case MoveType.wasteToFoundation:
        return _applyWasteToFoundation(move.to!, gameState);

      case MoveType.tableauToTableau:
        return _applyTableauToTableau(
          move.from,
          move.to!,
          move.cards,
          gameState,
        );

      case MoveType.tableauToFoundation:
        return _applyTableauToFoundation(move.from, move.to!, gameState);

      case MoveType.foundationToTableau:
        return _applyFoundationToTableau(move.from, move.to!, gameState);

      case MoveType.flipTableauCard:
        return _applyFlipTableauCard(move.from, gameState);

      case MoveType.resetStock:
        return _applyResetStock(gameState);
    }
  }

  /// Applique le mouvement stock vers défausse
  GameState _applyStockToWaste(GameState gameState) {
    final cardsToTake = gameState.drawMode == DrawMode.one ? 1 : 3;
    final actualCardsTaken = cardsToTake.clamp(0, gameState.stock.length);

    // IMPORTANT: Déplacer les cartes, ne pas les copier !
    // Prendre les cartes du dessus du stock
    final cardsFromStock =
        gameState.stock.cards.take(actualCardsTaken).toList();

    // Retirer ces cartes du stock
    final newStockCards = gameState.stock.cards.sublist(actualCardsTaken);

    // Les retourner face visible et les ajouter à la waste
    final newWasteCards = [
      ...gameState.waste.cards,
      ...cardsFromStock.map(
        (card) => Card(
          suit: card.suit,
          rank: card.rank,
          faceUp: true, // Face visible dans la waste
          id: card.id, // GARDER le même ID
        ),
      ),
    ];

    return gameState.copyWith(
      stock: gameState.stock.copyWith(cards: newStockCards),
      waste: gameState.waste.copyWith(cards: newWasteCards),
    );
  }

  /// Applique le mouvement défausse vers tableau
  GameState _applyWasteToTableau(int tableauIndex, GameState gameState) {
    final card = gameState.waste.topCard!;
    final newWaste = gameState.waste.removeTopCard();
    final newTableau = gameState.tableau[tableauIndex].addCard(card);

    return gameState
        .copyWith(waste: newWaste)
        .updateTableau(tableauIndex, newTableau);
  }

  /// Applique le mouvement défausse vers fondation
  GameState _applyWasteToFoundation(int foundationIndex, GameState gameState) {
    final card = gameState.waste.topCard!;
    final newWaste = gameState.waste.removeTopCard();
    final newFoundation = gameState.foundations[foundationIndex].addCard(card);

    return gameState
        .copyWith(waste: newWaste)
        .updateFoundation(foundationIndex, newFoundation);
  }

  /// Applique le mouvement tableau vers tableau
  GameState _applyTableauToTableau(
    int fromIndex,
    int toIndex,
    List<Card> cards,
    GameState gameState,
  ) {
    final fromPile = gameState.tableau[fromIndex];
    final toPile = gameState.tableau[toIndex];

    final newFromPile = fromPile.removeTopCards(cards.length);
    final newToPile = toPile.addCards(cards);

    return gameState
        .updateTableau(fromIndex, newFromPile)
        .updateTableau(toIndex, newToPile);
  }

  /// Applique le mouvement tableau vers fondation
  GameState _applyTableauToFoundation(
    int tableauIndex,
    int foundationIndex,
    GameState gameState,
  ) {
    final card = gameState.tableau[tableauIndex].topCard!;
    final newTableau = gameState.tableau[tableauIndex].removeTopCard();
    final newFoundation = gameState.foundations[foundationIndex].addCard(card);

    return gameState
        .updateTableau(tableauIndex, newTableau)
        .updateFoundation(foundationIndex, newFoundation);
  }

  /// Applique le mouvement fondation vers tableau
  GameState _applyFoundationToTableau(
    int foundationIndex,
    int tableauIndex,
    GameState gameState,
  ) {
    final card = gameState.foundations[foundationIndex].topCard!;
    final newFoundation =
        gameState.foundations[foundationIndex].removeTopCard();
    final newTableau = gameState.tableau[tableauIndex].addCard(card);

    return gameState
        .updateFoundation(foundationIndex, newFoundation)
        .updateTableau(tableauIndex, newTableau);
  }

  /// Applique le retournement d'une carte du tableau
  GameState _applyFlipTableauCard(int tableauIndex, GameState gameState) {
    final newTableau = gameState.tableau[tableauIndex].flipTopCard();
    return gameState.updateTableau(tableauIndex, newTableau);
  }

  /// Applique la remise à zéro du stock
  GameState _applyResetStock(GameState gameState) {
    // IMPORTANT: Déplacer les cartes de la waste vers le stock, ne pas les copier !
    final newStockCards = gameState.waste.cards.reversed
        .map(
          (card) => Card(
            suit: card.suit,
            rank: card.rank,
            faceUp: false, // Face down dans le stock
            id: card.id, // GARDER le même ID
          ),
        )
        .toList();

    return gameState.copyWith(
      stock: gameState.stock.copyWith(cards: newStockCards),
      waste: gameState.waste.copyWith(cards: []), // Vider la waste
      stockTurns: gameState.stockTurns + 1,
    );
  }

  /// Annule le dernier mouvement
  bool undo() {
    if (!state.canUndo) return false;

    // Sauvegarder le temps actuel pour le préserver
    final currentTime = state.time;

    // Filtrer les mouvements flipTableauCard car ils sont générés automatiquement
    final allMoves = state.moveHistory;

    // Trouver le dernier mouvement "réel" (non-flip) à annuler
    var lastRealMoveIndex = allMoves.length - 1;
    while (lastRealMoveIndex >= 0 &&
           allMoves[lastRealMoveIndex].type == MoveType.flipTableauCard) {
      lastRealMoveIndex--;
    }

    if (lastRealMoveIndex < 0) return false;

    // Garder seulement les mouvements jusqu'avant le dernier mouvement réel
    // et ses flips associés
    final movesToReplay = <Move>[];
    for (var i = 0; i < lastRealMoveIndex; i++) {
      // Ignorer les flipTableauCard car ils seront régénérés automatiquement
      if (allMoves[i].type != MoveType.flipTableauCard) {
        movesToReplay.add(allMoves[i]);
      }
    }

    // Recommencer la partie
    final initialState = _dealer.deal(state.seed, state.drawMode);

    // Rejouer tous les mouvements (sans les flips, ils seront auto-générés)
    var newState = initialState;
    for (final move in movesToReplay) {
      newState = _applyMove(move, newState);
      final points = _scorer.calculateMoveScore(move, newState);
      newState = newState.addMoveToHistory(move).addScore(points);
      // Auto-flip après chaque mouvement comme dans makeMove()
      newState = _autoFlipTableauCards(newState);
    }

    // Restaurer le temps et vider le redo
    state = newState.copyWith(
      time: currentTime,
      redoHistory: [], // Simplifier: vider le redo pour éviter les incohérences
    );

    return true;
  }

  /// Annule plusieurs mouvements d'un coup (pour appui long)
  /// Retourne le nombre de mouvements annulés (mouvements "réels", pas les flips)
  int undoMultiple(int count) {
    if (!state.canUndo || count <= 0) return 0;

    // Sauvegarder le temps actuel
    final currentTime = state.time;

    // Filtrer pour obtenir seulement les mouvements "réels" (non-flip)
    final allMoves = state.moveHistory;
    final realMoves = allMoves
        .where((m) => m.type != MoveType.flipTableauCard)
        .toList();

    if (realMoves.isEmpty) return 0;

    // Nombre de mouvements réels à annuler
    final realMovesToUndo = count.clamp(0, realMoves.length);
    final realMovesToKeep = realMoves.length - realMovesToUndo;

    // Garder seulement les premiers mouvements réels
    final movesToReplay = realMoves.sublist(0, realMovesToKeep);

    // Recommencer la partie
    final initialState = _dealer.deal(state.seed, state.drawMode);

    // Rejouer les mouvements à garder
    var newState = initialState;
    for (final move in movesToReplay) {
      newState = _applyMove(move, newState);
      final points = _scorer.calculateMoveScore(move, newState);
      newState = newState.addMoveToHistory(move).addScore(points);
      // Auto-flip après chaque mouvement
      newState = _autoFlipTableauCards(newState);
    }

    // Restaurer le temps
    state = newState.copyWith(
      time: currentTime,
      redoHistory: [], // Vider le redo pour éviter les incohérences
    );

    debugLog('Undo multiple: $realMovesToUndo mouvements annulés');
    return realMovesToUndo;
  }

  /// Refait le dernier mouvement annulé
  bool redo() {
    if (!state.canRedo) return false;

    final moveToRedo = state.redoHistory.last;
    return makeMove(moveToRedo);
  }

  /// Obtient un indice pour le joueur
  String? getHint() {
    final hint = _hintEngine.getBestHint(state);
    if (hint == null) return null;

    state = state.useHint();
    return hint.description;
  }

  /// Effectue un auto-move vers les fondations si possible
  bool autoMove() {
    final autoMoves = _rules.getAutoMoves(state);
    if (autoMoves.isEmpty) return false;

    // Effectue le premier auto-move disponible
    final result = makeMove(autoMoves.first);
    // _checkVictory() est déjà appelé dans makeMove()
    return result;
  }

  /// Effectue tous les auto-moves possibles
  int autoMoveAll() {
    var moveCount = 0;

    while (true) {
      final autoMoves = _rules.getAutoMoves(state);
      if (autoMoves.isEmpty) break;

      if (makeMove(autoMoves.first)) {
        moveCount++;
        // _checkVictory() est déjà appelé dans makeMove()
      } else {
        break;
      }
    }

    return moveCount;
  }

  /// Vérifie si l'auto-complete est disponible
  /// Conditions: stock vide, waste vide, toutes les cartes du tableau face visible
  bool canAutoComplete() {
    // Stock et waste doivent être vides
    if (state.stock.isNotEmpty || state.waste.isNotEmpty) {
      return false;
    }

    // Toutes les cartes du tableau doivent être face visible
    for (final pile in state.tableau) {
      for (final card in pile.cards) {
        if (!card.faceUp) {
          return false;
        }
      }
    }

    // Il doit rester des cartes à déplacer vers les fondations
    final cardsInTableau = state.tableau.fold<int>(
      0,
      (sum, pile) => sum + pile.cards.length,
    );

    return cardsInTableau > 0;
  }

  /// Auto-complete la partie en déplaçant toutes les cartes vers les fondations
  /// Retourne le nombre de cartes déplacées
  Future<int> autoCompleteGame() async {
    if (!canAutoComplete()) return 0;

    var movedCount = 0;
    var madeProgress = true;

    // Continuer tant qu'on peut faire des progrès
    while (madeProgress && !state.gameOver) {
      madeProgress = false;

      // Essayer de déplacer chaque carte du tableau vers une fondation
      for (var tableauIndex = 0; tableauIndex < state.tableau.length; tableauIndex++) {
        final pile = state.tableau[tableauIndex];
        if (pile.isEmpty) continue;

        final topCard = pile.topCard!;

        // Chercher une fondation qui accepte cette carte
        for (var foundationIndex = 0; foundationIndex < state.foundations.length; foundationIndex++) {
          final move = Move.tableauToFoundation(
            tableauIndex: tableauIndex,
            foundationIndex: foundationIndex,
            card: topCard,
          );

          if (_rules.isMoveLegal(move, state)) {
            if (makeMove(move)) {
              movedCount++;
              madeProgress = true;
              break; // Passer à la prochaine carte
            }
          }
        }

        if (madeProgress) break; // Recommencer depuis le début
      }
    }

    debugLog('Auto-complete: $movedCount cartes déplacées');
    return movedCount;
  }

  /// Gère le tap sur une carte (auto-move ou sélection)
  bool tapCard(Card card, {required String source, int? sourceIndex}) {
    // Tente d'abord un auto-move vers les fondations
    if (_tryAutoMoveToFoundations(card, source, sourceIndex)) {
      return true;
    }

    // Tente ensuite un auto-move vers le tableau (seulement depuis waste ou foundation)
    if (source == 'waste' || source == 'foundation') {
      if (_tryAutoMoveToTableau(card, source, sourceIndex)) {
        return true;
      }
    }

    // Sinon, ne fait rien pour l'instant (logique de sélection à implémenter)
    return false;
  }

  /// Tap-to-move intelligent pour seniors : déplace uniquement si UN seul coup valide
  /// Retourne (success, message) - message peut être null ou une explication du coup
  (bool, String?) tapToMoveCard(Card card, {required String source, int? sourceIndex}) {
    final validMoves = _getValidMovesForCard(card, source, sourceIndex);

    if (validMoves.isEmpty) {
      return (false, null);
    }

    if (validMoves.length == 1) {
      final move = validMoves.first;
      final success = makeMove(move);
      if (success) {
        final description = _getMoveDescription(move);
        return (true, description);
      }
      return (false, null);
    }

    // Plus d'un coup possible : ne rien faire (l'utilisateur doit choisir)
    return (false, 'Multiple moves possible');
  }

  /// Trouve tous les coups valides pour une carte donnée
  List<Move> _getValidMovesForCard(Card card, String source, int? sourceIndex) {
    final moves = <Move>[];

    // Vérifie les fondations
    for (var i = 0; i < state.foundations.length; i++) {
      Move? move;
      if (source == 'waste') {
        move = Move.wasteToFoundation(foundationIndex: i, card: card);
      } else if (source == 'tableau' && sourceIndex != null) {
        move = Move.tableauToFoundation(
          tableauIndex: sourceIndex,
          foundationIndex: i,
          card: card,
        );
      }
      if (move != null && _rules.isMoveLegal(move, state)) {
        moves.add(move);
      }
    }

    // Vérifie le tableau
    for (var i = 0; i < state.tableau.length; i++) {
      Move? move;
      if (source == 'waste') {
        move = Move.wasteToTableau(card: card, tableauIndex: i);
      } else if (source == 'tableau' && sourceIndex != null) {
        // Tableau vers tableau - récupère les cartes à déplacer
        final cardsToMove = _getCardsToMoveFromTableau(sourceIndex, card);
        if (cardsToMove.isNotEmpty && i != sourceIndex) {
          move = Move.tableauToTableau(
            fromIndex: sourceIndex,
            toIndex: i,
            cards: cardsToMove,
          );
        }
      } else if (source == 'foundation' && sourceIndex != null) {
        move = Move.foundationToTableau(
          foundationIndex: sourceIndex,
          tableauIndex: i,
          card: card,
        );
      }
      if (move != null && _rules.isMoveLegal(move, state)) {
        moves.add(move);
      }
    }

    return moves;
  }

  /// Génère une description simple du coup pour l'affichage
  String _getMoveDescription(Move move) {
    switch (move.type) {
      case MoveType.wasteToFoundation:
      case MoveType.tableauToFoundation:
        return 'Moved to foundation';
      case MoveType.wasteToTableau:
      case MoveType.tableauToTableau:
      case MoveType.foundationToTableau:
        return 'Moved to tableau';
      default:
        return 'Move completed';
    }
  }

  /// Tente un auto-move vers les fondations
  bool _tryAutoMoveToFoundations(Card card, String source, int? sourceIndex) {
    for (var i = 0; i < state.foundations.length; i++) {
      final foundation = state.foundations[i];
      if (foundation.canAcceptCard(card)) {
        Move? move;

        if (source == 'waste') {
          move = Move.wasteToFoundation(foundationIndex: i, card: card);
        } else if (source == 'tableau' && sourceIndex != null) {
          move = Move.tableauToFoundation(
            tableauIndex: sourceIndex,
            foundationIndex: i,
            card: card,
          );
        }

        if (move != null && _rules.isMoveLegal(move, state)) {
          return makeMove(move);
        }
      }
    }

    return false;
  }

  /// Tente un auto-move vers le tableau
  bool _tryAutoMoveToTableau(Card card, String source, int? sourceIndex) {
    for (var i = 0; i < state.tableau.length; i++) {
      final tableauPile = state.tableau[i];
      if (tableauPile.canAcceptCard(card)) {
        Move? move;

        if (source == 'waste') {
          move = Move.wasteToTableau(card: card, tableauIndex: i);
        } else if (source == 'foundation' && sourceIndex != null) {
          move = Move.foundationToTableau(
            foundationIndex: sourceIndex,
            tableauIndex: i,
            card: card,
          );
        }

        if (move != null && _rules.isMoveLegal(move, state)) {
          return makeMove(move);
        }
      }
    }

    return false;
  }

  /// Met en pause ou reprend la partie
  void togglePause() {
    if (state.status == GameStatus.playing) {
      state = state.pause();
    } else if (state.status == GameStatus.paused) {
      state = state.resume();
    }
  }

  /// Met à jour le temps de jeu
  void updateTime(Duration newTime) {
    if (state.status == GameStatus.playing) {
      state = state.updateTime(newTime);
    }
  }

  /// Obtient les mouvements légaux actuels
  List<Move> getLegalMoves() {
    return _rules.getLegalMoves(state);
  }

  /// Vérifie si la partie est gagnée
  bool get isWon => _rules.isGameWon(state);

  /// Vérifie si la partie est perdue
  bool get isLost => _rules.isGameLost(state);

  /// Obtient les statistiques de la partie
  Map<String, dynamic> getGameStats() {
    return _scorer.calculateGameStats(state);
  }

  /// Valide l'intégrité des cartes dans l'état du jeu
  bool _validateCardIntegrity() {
    return _validateCardIntegrityForState(state);
  }

  /// Valide l'intégrité des cartes pour un état donné
  bool _validateCardIntegrityForState(GameState gameState) {
    final allCards = <String>[];
    final cardLocations = <String, List<String>>{};

    // Fonction helper pour traquer les emplacements des cartes
    void addCardsFromPile(List<Card> cards, String pileName) {
      for (final card in cards) {
        allCards.add(card.id);
        cardLocations.putIfAbsent(card.id, () => []).add(pileName);
      }
    }

    // Collecte toutes les cartes ID depuis toutes les piles
    addCardsFromPile(gameState.stock.cards, 'stock');
    addCardsFromPile(gameState.waste.cards, 'waste');

    for (var i = 0; i < gameState.foundations.length; i++) {
      addCardsFromPile(gameState.foundations[i].cards, 'foundation_$i');
    }

    for (var i = 0; i < gameState.tableau.length; i++) {
      addCardsFromPile(gameState.tableau[i].cards, 'tableau_$i');
    }

    // Vérifie l'unicité des cartes
    final uniqueCards = allCards.toSet();
    if (uniqueCards.length != allCards.length) {
      print('🚨 ERREUR: Cartes dupliquées détectées!');
      print(
        'Total cartes: ${allCards.length}, Cartes uniques: ${uniqueCards.length}',
      );

      // Trouve les doublons et leurs emplacements
      final duplicates = <String>[];
      final seen = <String>{};
      for (final cardId in allCards) {
        if (seen.contains(cardId)) {
          if (!duplicates.contains(cardId)) {
            duplicates.add(cardId);
          }
        } else {
          seen.add(cardId);
        }
      }

      print('Cartes dupliquées: $duplicates');
      for (final cardId in duplicates) {
        print('  $cardId trouvée dans: ${cardLocations[cardId]}');
      }
      return false;
    }

    // Vérifie qu'on a exactement 52 cartes
    if (allCards.length != 52) {
      print('🚨 ERREUR: Nombre de cartes incorrect: ${allCards.length}/52');
      return false;
    }

    return true;
  }

  /// Getter pour le completer de victoire (pour l'UI)
  Future<void>? get victoryNotification => _victoryCompleter?.future;
}

/// Provider principal pour le contrôleur de jeu
final gameControllerProvider =
    StateNotifierProvider<GameController, GameState>((ref) {
  final repo = ref.read(gameRepositoryProvider);
  final statsRepo = ref.read(gameStatsRepositoryProvider);
  return GameController(repo, statsRepo);
});
