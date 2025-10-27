import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

/// Liste des sessions de jeu récentes
class RecentSessionsList extends StatelessWidget {
  const RecentSessionsList({
    required this.sessions,
    super.key,
  });

  final List<GameSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    final l10n = S.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.recentGames,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${sessions.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Liste des sessions
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionListItem(
                  session: session,
                  isFirst: index == 0,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour un item de session individuel
class _SessionListItem extends StatelessWidget {
  const _SessionListItem({
    required this.session,
    this.isFirst = false,
  });

  final GameSession session;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    final dateFormat =
        DateFormat.yMd(Localizations.localeOf(context).languageCode);
    final timeFormat =
        DateFormat.Hm(Localizations.localeOf(context).languageCode);

    return Semantics(
      label: _buildSemanticLabel(l10n),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: CircleAvatar(
          backgroundColor: session.won
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            session.won ? Icons.check : Icons.close,
            color: session.won ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            // Résultat et seed
            Expanded(
              child: Text(
                '${session.won ? l10n.gameWon : l10n.gameLost} • Seed ${session.seed}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isFirst ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),

            // Mode de pioche
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.drawMode == DrawMode.draw1 ? '1' : '3',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            // Durée
            Icon(
              Icons.timer,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(session.duration),
              style: Theme.of(context).textTheme.labelSmall,
            ),

            const SizedBox(width: 12),

            // Coups
            Icon(
              Icons.touch_app,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${session.moves} ${l10n.moves.toLowerCase()}',
              style: Theme.of(context).textTheme.labelSmall,
            ),

            const SizedBox(width: 12),

            // Score
            Icon(
              Icons.star,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              session.scoreStandard.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),

            const Spacer(),

            // Date
            Text(
              '${dateFormat.format(session.endedAt)} ${timeFormat.format(session.endedAt)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        trailing: session.aborted
            ? const Icon(
                Icons.warning,
                color: Colors.orange,
                size: 16,
              )
            : null,
      ),
    );
  }

  /// Formate une durée en format lisible
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Construit un label sémantique pour l'accessibilité
  String _buildSemanticLabel(S l10n) {
    final result = session.won ? l10n.gameWon : l10n.gameLost;
    final duration = _formatDuration(session.duration);
    final drawMode = session.drawMode == DrawMode.draw1
        ? l10n.filterDrawMode1Card
        : l10n.filterDrawMode3Cards;

    return '$result, seed ${session.seed}, $drawMode, '
        'durée $duration, ${session.moves} coups, '
        'score ${session.scoreStandard}';
  }
}
