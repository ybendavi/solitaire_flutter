import 'package:flutter/material.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/stats_providers.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

/// Grille des indicateurs clés de performance
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    required this.data,
    super.key,
  });

  final StatsViewModel data;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 colonnes sur mobile, 3 sur tablette
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            // Taux de victoire (KPI principal)
            _KpiCard(
              title: l10n.winRate,
              value: '${(data.winRate * 100).toStringAsFixed(1)}%',
              icon: Icons.emoji_events,
              color: _getWinRateColor(context, data.winRate),
              isHighlighted: true,
              semanticLabel:
                  l10n.winRateSemantics((data.winRate * 100).round()),
            ),

            // Parties jouées
            _KpiCard(
              title: l10n.gamesPlayed,
              value: data.games.toString(),
              icon: Icons.casino,
              color: Theme.of(context).colorScheme.primary,
              semanticLabel: l10n.gamesPlayedSemantics(data.games),
            ),

            // Parties gagnées
            _KpiCard(
              title: l10n.gamesWon,
              value: data.wins.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              semanticLabel: l10n.gamesWonSemantics(data.wins),
            ),

            // Meilleur temps
            _KpiCard(
              title: l10n.bestTime,
              value: _formatDuration(data.bestTime),
              icon: Icons.timer,
              color: Colors.orange,
              semanticLabel: l10n
                  .bestTimeSemantics(_formatDurationAccessible(data.bestTime)),
            ),

            // Temps moyen
            _KpiCard(
              title: l10n.avgTime,
              value: _formatDuration(data.avgTime),
              icon: Icons.schedule,
              color: Colors.blue,
              semanticLabel: l10n
                  .avgTimeSemantics(_formatDurationAccessible(data.avgTime)),
            ),

            // Coups moyens
            _KpiCard(
              title: l10n.avgMoves,
              value: data.avgMoves.toStringAsFixed(1),
              icon: Icons.touch_app,
              color: Colors.purple,
              semanticLabel: l10n.avgMovesSemantics(data.avgMoves.round()),
            ),

            // Score Vegas
            if (data.vegasBankroll != 0)
              _KpiCard(
                title: l10n.vegasBankroll,
                value: data.vegasBankroll >= 0
                    ? '+\$${data.vegasBankroll}'
                    : '-\$${data.vegasBankroll.abs()}',
                icon: Icons.attach_money,
                color: data.vegasBankroll >= 0 ? Colors.green : Colors.red,
                semanticLabel: l10n.vegasBankrollSemantics(data.vegasBankroll),
              ),

            // Streak actuel
            _KpiCard(
              title: l10n.currentStreak,
              value: data.currentStreak.toString(),
              icon: Icons.local_fire_department,
              color: data.currentStreak > 0 ? Colors.orange : Colors.grey,
              semanticLabel: l10n.currentStreakSemantics(data.currentStreak),
            ),

            // Meilleur streak
            _KpiCard(
              title: l10n.bestStreak,
              value: data.bestStreak.toString(),
              icon: Icons.military_tech,
              color: Colors.amber,
              semanticLabel: l10n.bestStreakSemantics(data.bestStreak),
            ),
          ],
        );
      },
    );
  }

  /// Détermine la couleur du taux de victoire selon sa valeur
  Color _getWinRateColor(BuildContext context, double winRate) {
    if (winRate >= 0.7) return Colors.green;
    if (winRate >= 0.5) return Colors.orange;
    if (winRate >= 0.3) return Colors.red;
    return Colors.grey;
  }

  /// Formate une durée en format lisible
  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '--';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formate une durée pour l'accessibilité
  String _formatDurationAccessible(Duration duration) {
    if (duration == Duration.zero) return 'aucun temps enregistré';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '$minutes minute${minutes > 1 ? 's' : ''} et $seconds seconde${seconds > 1 ? 's' : ''}';
    } else {
      return '$seconds seconde${seconds > 1 ? 's' : ''}';
    }
  }
}

/// Widget pour une carte KPI individuelle
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.semanticLabel,
    this.isHighlighted = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String semanticLabel;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Card(
        elevation: isHighlighted ? 4 : 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isHighlighted ? 32 : 28,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: isHighlighted
                    ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        )
                    : Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
