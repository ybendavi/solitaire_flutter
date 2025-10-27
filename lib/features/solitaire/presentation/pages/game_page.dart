import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/generated/l10n.dart';
import 'package:solitaire_klondike/core/theme/app_theme.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/providers.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/card_view.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/pile_widgets.dart'
    as pile_widgets;
import 'package:solitaire_klondike/features/solitaire/presentation/layout/board_layout.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/animation/deal_animator.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/victory_overlay.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/stats_snapshot.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_result.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart'
    as game;

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  bool _showDebugOverlay = false;
  GameStatus? _previousGameStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = ref.read(gameControllerProvider.notifier);
      if (!ctrl.hasRestorableGame()) {
        ctrl.newGame();
      } else {
        ctrl.restoreGame();
      }
    });
  }

  /// Lance l'animation de distribution des cartes
  Future<void> _startDealAnimation(BoardLayout layout) async {
    final gameController = ref.read(gameControllerProvider.notifier);
    final plan = gameController.pendingDealPlan;

    if (plan == null) return;

    try {
      gameController.setUiLocked(true);

      final animator = DealAnimator(
        context: context,
        layout: layout,
        controller: gameController,
      );

      await animator.run(
        plan: plan,
        perCard: const Duration(milliseconds: 80),
      );

      gameController.completeDealAnimation();
    } catch (e) {
      debugPrint("Erreur lors de l'animation de distribution: $e");
      // En cas d'erreur, finaliser quand même la distribution
      gameController.completeDealAnimation();
    } finally {
      gameController.setUiLocked(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final gameController = ref.read(gameControllerProvider.notifier);
    final l10n = S.of(context)!;
    final media = MediaQuery.of(context);

    final layout = BoardLayout(
      media.size,
      media.padding,
      // Espacements plus généreux pour éviter les chevauchements
      hGap: media.size.width < 600 ? 12 : 16, // Augmenté
      vGap: media.size.width < 600 ? 16 : 20, // Augmenté
      additionalPadding: media.size.width < 600 ? 12 : 20, // Augmenté
    );

    // Détecter si on doit lancer l'animation de distribution
    if (_previousGameStatus != gameState.status &&
        gameState.status == GameStatus.dealing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDealAnimation(layout);
      });
    }
    _previousGameStatus = gameState.status;

    return Scaffold(
      backgroundColor: context.gameColors.tableBackground,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              setState(() {
                _showDebugOverlay = !_showDebugOverlay;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_game':
                  gameController.newGame();
                case 'restart':
                  gameController.newGame();
                case 'hint':
                  _showHint(gameController);
                case 'toggle_draw_mode':
                  gameController.toggleDrawMode();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'new_game',
                child: Text(l10n.newGame),
              ),
              PopupMenuItem(
                value: 'restart',
                child: Text(l10n.newGame),
              ),
              PopupMenuItem(
                value: 'hint',
                child: Text(l10n.hint),
              ),
              const PopupMenuItem(
                value: 'toggle_draw_mode',
                child: Text(
                  r'Pioche: ${gameState.drawMode == DrawMode.one ? "1 carte" : "3 cartes"}',
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHUD(context, gameState, l10n),
            Expanded(
              child: Stack(
                children: [
                  // Placeholders pour les zones de drop (en arrière-plan)
                  ..._buildPlaceholders(
                    layout,
                    gameState,
                    gameController,
                    media.size.width < 600,
                  ),
                  // Cartes positionnées (au premier plan)
                  ..._buildPositionedCards(layout, gameState, gameController),
                  // Overlay de debug optionnel
                  if (_showDebugOverlay)
                    pile_widgets.DebugOverlay(
                      debugRects: layout.getDebugRects(),
                    ),
                  // Overlay de victoire
                  if (gameState.gameOver &&
                      gameState.gameResult == GameResult.win)
                    VictoryOverlay(
                      stats: StatsSnapshot.fromState(gameState),
                      foundationRects: layout.foundationRects,
                      onReplay: () {
                        gameController.setUiLocked(false);
                        gameController.newGame();
                      },
                      onBackToMenu: () {
                        gameController.setUiLocked(false);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHUD(BuildContext context, GameState gameState, S l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHUDItem(l10n.score, gameState.score.toString()),
          _buildHUDItem(l10n.moves, gameState.moves.toString()),
          _buildHUDItem(l10n.time, _formatTime(gameState.time)),
        ],
      ),
    );
  }

  Widget _buildHUDItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlaceholders(
    BoardLayout layout,
    GameState gameState,
    GameController gameController,
    bool isMobile,
  ) {
    return [
      // Stock pile placeholder
      Positioned.fromRect(
        rect: layout.stockRect,
        child: pile_widgets.PileDropTarget(
          onAccept: (game.Card card) {
            // Stock n'accepte normalement aucune carte
          },
          onWillAccept: (game.Card? card) => false,
          child: pile_widgets.PilePlaceholder(
            type: 'stock',
            width: layout.cardWidth,
            height: layout.cardHeight,
            onTap: gameState.stock.isEmpty && gameState.canResetStock
                ? () => gameController.recycleWasteToStock()
                : gameState.stock.isNotEmpty
                    ? () => gameController.tapStock()
                    : null,
          ),
        ),
      ),

      // Waste pile placeholder
      Positioned.fromRect(
        rect: layout.wasteRect,
        child: pile_widgets.PileDropTarget(
          onAccept: (game.Card card) {
            // Waste n'accepte normalement aucune carte
          },
          onWillAccept: (game.Card? card) => false,
          child: pile_widgets.PilePlaceholder(
            type: 'waste',
            width: layout.cardWidth,
            height: layout.cardHeight,
          ),
        ),
      ),

      // Foundation pile placeholders - étendus pour capturer les drops
      ...layout.foundationRects.asMap().entries.map((entry) {
        final index = entry.key;
        final rect = entry.value;
        // Calcul adaptatif des extensions pour mobile/desktop (réduit car plus d'espacement)
        final extendSides = isMobile ? 8 : 6;
        final extendTop = isMobile ? 8 : 6;
        final extendBottom = isMobile ? 25 : 20;

        return Positioned(
          left: rect.left - extendSides, // Étendre à gauche
          top: rect.top - extendTop, // Étendre vers le haut
          width: rect.width + (extendSides * 2), // Étendre la largeur
          height: rect.height + extendBottom, // Étendre vers le bas
          child: pile_widgets.PileDropTarget(
            onAccept: (game.Card card) {
              print('[GamePage] Accepting card on foundation $index');
              gameController.dropCardOnFoundation(card, index);
            },
            onWillAccept: (game.Card? card) {
              return card != null &&
                  gameController.canDropCardOn(card, 'foundation', index);
            },
            child: ColoredBox(
              color: Colors.transparent,
              child: pile_widgets.PilePlaceholder(
                type: 'foundation',
                width: layout.cardWidth,
                height: layout.cardHeight,
              ),
            ),
          ),
        );
      }),

      // Tableau column placeholders - étendus pour couvrir toute la hauteur
      ...layout.tableauColumnRects.asMap().entries.map((entry) {
        final index = entry.key;
        final rect = entry.value;
        final pile = gameState.tableau[index];

        // Calculer la hauteur totale de la colonne
        final totalHeight =
            rect.height + (pile.cards.length * layout.faceUpOffset) + 50;

        // Extensions adaptatives pour les tableaux (réduit car plus d'espacement)
        final extendSides = isMobile ? 8 : 6;
        final extendTop = isMobile ? 8 : 6;
        final extendBottom = isMobile ? 15 : 10;

        return Positioned(
          left: rect.left - extendSides, // Étendre à gauche
          top: rect.top - extendTop, // Étendre vers le haut
          width: rect.width + (extendSides * 2), // Étendre la largeur
          height: totalHeight + extendBottom, // Étendre encore plus vers le bas
          child: pile_widgets.PileDropTarget(
            onAccept: (game.Card card) {
              print('[GamePage] Accepting card on tableau $index');
              gameController.dropCardOnTableau(card, index);
            },
            onWillAccept: (game.Card? card) {
              return card != null &&
                  gameController.canDropCardOn(card, 'tableau', index);
            },
            child: ColoredBox(
              color: Colors.transparent,
              child: pile_widgets.PilePlaceholder(
                type: 'tableau',
                width: layout.cardWidth,
                height: layout.cardHeight,
              ),
            ),
          ),
        );
      }),
    ];
  }

  List<Widget> _buildPositionedCards(
    BoardLayout layout,
    GameState gameState,
    GameController gameController,
  ) {
    final cards = <Widget>[];

    // Stock pile - carte du dessus si présente
    if (gameState.stock.isNotEmpty) {
      cards.add(
        _buildCard(
          layout.stockRect.topLeft,
          gameState.stock.topCard!,
          layout,
          key: ValueKey('stock_${gameState.stock.topCard!.id}'),
          onTap: () => gameController.tapStock(),
        ),
      );
    }

    // Waste pile - cartes visibles en éventail
    for (var i = 0; i < gameState.waste.cards.length; i++) {
      final card = gameState.waste.cards[i];
      final position = layout.cardOffsetInWaste(i);
      cards.add(
        _buildCard(
          position,
          card,
          layout,
          key: ValueKey('waste_${card.id}'),
          isDraggable: i ==
              gameState.waste.cards.length -
                  1, // Seule la dernière est draggable
          onTap: i == gameState.waste.cards.length - 1
              ? () => gameController.tapCard(card, source: 'waste')
              : null,
        ),
      );
    }

    // Foundation piles - carte du dessus de chaque fondation
    for (var foundationIndex = 0;
        foundationIndex < gameState.foundations.length;
        foundationIndex++) {
      final foundation = gameState.foundations[foundationIndex];
      if (foundation.isNotEmpty) {
        final card = foundation.topCard!;
        final position = layout.foundationRects[foundationIndex].topLeft;
        cards.add(
          _buildCard(
            position,
            card,
            layout,
            key: ValueKey('foundation_${foundationIndex}_${card.id}'),
            isDraggable: true,
          ),
        );
      }
    }

    // Tableau columns - toutes les cartes empilées
    for (var columnIndex = 0;
        columnIndex < gameState.tableau.length;
        columnIndex++) {
      final pile = gameState.tableau[columnIndex];
      for (var cardIndex = 0; cardIndex < pile.cards.length; cardIndex++) {
        final card = pile.cards[cardIndex];
        final position = layout.cardOffsetInTableau(
          columnIndex,
          cardIndex,
          faceUp: card.faceUp,
        );
        cards.add(
          _buildCard(
            position,
            card,
            layout,
            key: ValueKey('tableau_${columnIndex}_${card.id}'),
            isDraggable: card.faceUp,
            onTap: card.faceUp
                ? () => gameController.tapCard(
                      card,
                      source: 'tableau',
                      sourceIndex: columnIndex,
                    )
                : null,
          ),
        );
      }
    }

    return cards;
  }

  Widget _buildCard(
    Offset position,
    game.Card card,
    BoardLayout layout, {
    required Key key,
    bool isDraggable = false,
    VoidCallback? onTap,
  }) {
    return AnimatedPositioned(
      key: key,
      left: position.dx,
      top: position.dy,
      width: layout.cardWidth,
      height: layout.cardHeight,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        ignoring: !isDraggable &&
            onTap == null, // Ignore events only for non-interactive cards
        child: CardView(
          card: card,
          isDraggable: isDraggable,
          onTap: onTap,
          onDragStarted: isDraggable
              ? () =>
                  print('[GamePage] Drag started: ${card.rank} of ${card.suit}')
              : null,
          onDragCompleted: isDraggable
              ? () => print(
                    '[GamePage] Drag completed: ${card.rank} of ${card.suit}',
                  )
              : null,
          onDragEnd: isDraggable ? () => print('[GamePage] Drag ended') : null,
        ),
      ),
    );
  }

  void _showHint(GameController gameController) {
    final hint = gameController.getHint();
    if (hint != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hint)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.noHintAvailable)),
      );
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
