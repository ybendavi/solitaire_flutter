import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/generated/l10n.dart';
import 'package:solitaire_klondike/core/theme/app_theme.dart';
import 'package:solitaire_klondike/core/utils/responsive.dart';
import 'package:solitaire_klondike/core/utils/settings_service.dart';
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
    final settings = ref.watch(settingsProvider);
    final l10n = S.of(context)!;
    final media = MediaQuery.of(context);
    final responsive = context.responsive;

    // BoardLayout avec multiplicateur de taille pour l'accessibilité seniors
    final layout = BoardLayout(
      media.size,
      media.padding,
      cardSizeMultiplier: settings.cardSizeMultiplier,
    );

    // Détecter si on doit lancer l'animation de distribution
    if (_previousGameStatus != gameState.status &&
        gameState.status == GameStatus.dealing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDealAnimation(layout);
      });
    }
    _previousGameStatus = gameState.status;

    // Utiliser les couleurs Serenity si le mode est activé
    final gameColors = settings.serenityMode
        ? GameColors.serenity
        : context.gameColors;

    return Scaffold(
      backgroundColor: gameColors.tableBackground,
      appBar: _buildResponsiveAppBar(context, gameState, gameController, l10n, responsive),
      body: SafeArea(
        child: Column(
          children: [
            _buildHUD(context, gameState, settings, l10n, responsive),
            Expanded(
              child: Stack(
                children: [
                  // Placeholders pour les zones de drop (en arrière-plan)
                  ..._buildPlaceholders(
                    layout,
                    gameState,
                    gameController,
                    responsive,
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

  PreferredSizeWidget _buildResponsiveAppBar(
    BuildContext context,
    GameState gameState,
    GameController gameController,
    S l10n,
    ResponsiveInfo responsive,
  ) {
    final toolbarHeight = responsive.responsive<double>(
      phone: responsive.isLandscape ? 40 : 48,
      tablet: 56,
      desktop: 64,
    );

    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.8),
      foregroundColor: Colors.white,
      toolbarHeight: toolbarHeight,
      title: Text(
        l10n.appTitle,
        style: TextStyle(
          fontSize: responsive.responsive<double>(
            phone: responsive.isLandscape ? 16 : 18,
            tablet: 20,
            desktop: 22,
          ),
        ),
      ),
      actions: [
        // Bouton Undo - tap = 1, appui long = 5
        GestureDetector(
          onTap: gameState.canUndo
              ? () {
                  if (gameController.undo()) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Undo'),
                        duration: Duration(milliseconds: 500),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              : null,
          onLongPress: gameState.canUndo
              ? () {
                  final count = gameController.undoMultiple(5);
                  if (count > 0) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Undo x$count'),
                        duration: const Duration(milliseconds: 800),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.undo,
              size: responsive.responsive<double>(
                phone: 22,
                tablet: 26,
                desktop: 30,
              ),
              color: gameState.canUndo ? Colors.white : Colors.white38,
            ),
          ),
        ),

        // Bouton Auto-complete (visible seulement quand disponible)
        if (gameController.canAutoComplete())
          IconButton(
            icon: Icon(
              Icons.fast_forward,
              size: responsive.responsive<double>(
                phone: 22,
                tablet: 26,
                desktop: 30,
              ),
            ),
            tooltip: 'Auto-complete',
            onPressed: () async {
              final count = await gameController.autoCompleteGame();
              if (count > 0 && mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$count cards moved'),
                    duration: const Duration(milliseconds: 800),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),

        IconButton(
          icon: Icon(
            Icons.bug_report,
            size: responsive.responsive<double>(
              phone: 20,
              tablet: 24,
              desktop: 28,
            ),
          ),
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
    );
  }

  Widget _buildHUD(
    BuildContext context,
    GameState gameState,
    AppSettings settings,
    S l10n,
    ResponsiveInfo responsive,
  ) {
    final padding = responsive.responsive<double>(
      phone: responsive.isLandscape ? 8 : 12,
      tablet: 16,
      desktop: 20,
    );

    final labelFontSize = responsive.responsive<double>(
      phone: responsive.isLandscape ? 10 : 11,
      tablet: 12,
      desktop: 14,
    );

    final valueFontSize = responsive.responsive<double>(
      phone: responsive.isLandscape ? 14 : 16,
      tablet: 18,
      desktop: 20,
    );

    // Construire les items du HUD selon les settings (Mode Sérénité)
    final hudItems = <Widget>[];

    if (settings.showScore) {
      hudItems.add(
        _buildHUDItem(
          l10n.score,
          gameState.score.toString(),
          labelFontSize,
          valueFontSize,
        ),
      );
    }

    // Toujours afficher les moves
    hudItems.add(
      _buildHUDItem(
        l10n.moves,
        gameState.moves.toString(),
        labelFontSize,
        valueFontSize,
      ),
    );

    if (settings.showTimer) {
      hudItems.add(
        _buildHUDItem(
          l10n.time,
          _formatTime(gameState.time),
          labelFontSize,
          valueFontSize,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
      color: Colors.black.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: hudItems,
      ),
    );
  }

  Widget _buildHUDItem(
    String label,
    String value,
    double labelFontSize,
    double valueFontSize,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: labelFontSize,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueFontSize,
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
    ResponsiveInfo responsive,
  ) {
    // Extensions adaptatives selon le type d'appareil
    final extendSides = responsive.responsive<double>(
      phone: responsive.isLandscape ? 6 : 8,
      tablet: 6,
      desktop: 4,
    );
    final extendTop = responsive.responsive<double>(
      phone: responsive.isLandscape ? 6 : 8,
      tablet: 6,
      desktop: 4,
    );
    final extendBottomFoundation = responsive.responsive<double>(
      phone: responsive.isLandscape ? 18 : 25,
      tablet: 20,
      desktop: 15,
    );
    final extendBottomTableau = responsive.responsive<double>(
      phone: responsive.isLandscape ? 12 : 15,
      tablet: 12,
      desktop: 10,
    );

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

        return Positioned(
          left: rect.left - extendSides,
          top: rect.top - extendTop,
          width: rect.width + (extendSides * 2),
          height: rect.height + extendBottomFoundation,
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

        return Positioned(
          left: rect.left - extendSides,
          top: rect.top - extendTop,
          width: rect.width + (extendSides * 2),
          height: totalHeight + extendBottomTableau,
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

    // Récupérer le setting tapToMove
    final settings = ref.read(settingsProvider);

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
              ? () => _handleCardTap(card, 'waste', null, gameController, settings.tapToMove)
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
                ? () => _handleCardTap(card, 'tableau', columnIndex, gameController, settings.tapToMove)
                : null,
          ),
        );
      }
    }

    return cards;
  }

  /// Gère le tap sur une carte selon le mode (tap-to-move ou normal)
  void _handleCardTap(
    game.Card card,
    String source,
    int? sourceIndex,
    GameController controller,
    bool tapToMoveEnabled,
  ) {
    if (tapToMoveEnabled) {
      // Mode tap-to-move : déplace uniquement si un seul coup valide
      final (success, message) = controller.tapToMoveCard(
        card,
        source: source,
        sourceIndex: sourceIndex,
      );
      if (success && message != null) {
        // Feedback discret pour le senior
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Mode normal : auto-move agressif
      controller.tapCard(card, source: source, sourceIndex: sourceIndex);
    }
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
