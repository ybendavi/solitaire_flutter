import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:solitaire_klondike/generated/l10n.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/stats_snapshot.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/confetti_painter.dart';
import 'package:solitaire_klondike/core/utils/settings_service.dart';

/// Overlay affiché lors de la victoire avec animation et panneau de résultats
class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    required this.stats,
    required this.onReplay,
    required this.onBackToMenu,
    super.key,
    this.duration = const Duration(milliseconds: 2200),
    this.foundationRects = const [],
  });

  final StatsSnapshot stats;
  final VoidCallback onReplay;
  final VoidCallback onBackToMenu;
  final Duration duration;
  final List<Rect> foundationRects; // Pour l'animation cascade

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _cascadeController;
  late AnimationController _panelController;
  late Animation<double> _confettiAnimation;
  late Animation<double> _cascadeAnimation;
  late Animation<double> _panelAnimation;

  bool _showPanel = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();

    // Vérifier les paramètres d'accessibilité
    _reduceMotion = SettingsService.shouldSkipAnimations;

    _setupAnimations();
    _startAnimations();
    _announceVictory();
  }

  void _setupAnimations() {
    // Animation des confettis
    _confettiController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOutQuart,
    );

    // Animation cascade des fondations
    _cascadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cascadeAnimation = CurvedAnimation(
      parent: _cascadeController,
      curve: Curves.easeOutBack,
    );

    // Animation du panneau
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutBack,
    );
  }

  void _startAnimations() {
    if (_reduceMotion) {
      // Animation réduite : affichage direct du panneau
      setState(() {
        _showPanel = true;
      });
      _panelController.forward();
    } else {
      // Animation complète
      _confettiController.forward();
      _cascadeController.forward();

      // Afficher le panneau après 900ms
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _showPanel = true;
          });
          _panelController.forward();
        }
      });
    }
  }

  void _announceVictory() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Annonce d'accessibilité après que le widget soit construit
      final l10n = S.of(context)!;
      SemanticsService.announce(l10n.victoryAnnounce, TextDirection.ltr);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cascadeController.dispose();
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      child: Stack(
        children: [
          // Animation de confettis
          if (!_reduceMotion)
            AnimatedBuilder(
              animation: _confettiAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    progress: _confettiAnimation.value,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Animation CASCADE des fondations
          if (!_reduceMotion && widget.foundationRects.isNotEmpty)
            AnimatedBuilder(
              animation: _cascadeAnimation,
              builder: (context, child) {
                return _buildFoundationGlow();
              },
            ),

          // Panneau de victoire
          if (_showPanel)
            Center(
              child: AnimatedBuilder(
                animation: _panelAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _panelAnimation.value,
                    child: _buildVictoryPanel(context),
                  );
                },
              ),
            ),

          // Badge "Victoire!" pour mode réduit
          if (_reduceMotion && _showPanel)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _panelAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _panelAnimation.value,
                    child: _buildVictoryBadge(context),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoundationGlow() {
    return Stack(
      children: widget.foundationRects.asMap().entries.map((entry) {
        final index = entry.key;
        final rect = entry.value;
        final delay = index * 0.25; // Délai entre chaque fondation
        final glowProgress = math.max(
          0,
          math.min(1, (_cascadeAnimation.value - delay) / 0.25),
        );

        return Positioned.fromRect(
          rect: rect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: glowProgress > 0
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.6 * glowProgress),
                        blurRadius: 20 * glowProgress.toDouble(),
                        spreadRadius: 5 * glowProgress.toDouble(),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVictoryBadge(BuildContext context) {
    final l10n = S.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        child: Text(
          l10n.victoryTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryPanel(BuildContext context) {
    final l10n = S.of(context)!;
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        minWidth: 320,
        maxWidth: 480,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              Text(
                l10n.victoryTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                semanticsLabel: l10n.victoryAnnounce,
              ),

              const SizedBox(height: 24),

              // Statistiques
              _buildStatsGrid(context),

              const SizedBox(height: 32),

              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Bouton Retour au menu
                  OutlinedButton(
                    onPressed: widget.onBackToMenu,
                    child: Text(l10n.backToMenuButton),
                  ),

                  // Bouton Rejouer
                  FilledButton(
                    onPressed: widget.onReplay,
                    child: Text(l10n.replayButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final l10n = S.of(context)!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              label: l10n.labelTime,
              value: widget.stats.formattedTime,
              icon: Icons.access_time,
            ),
            _buildStatItem(
              context,
              label: l10n.labelMoves,
              value: widget.stats.moves.toString(),
              icon: Icons.touch_app,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          context,
          label: l10n.labelScore,
          value: widget.stats.score.toString() +
              (widget.stats.isVegas ? r' $' : ''),
          icon: Icons.stars,
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isLarge = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: isLarge ? 32 : 24,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: (isLarge
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
