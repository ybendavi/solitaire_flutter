import 'package:flutter/material.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';

/// Widget pour afficher une tendance sous forme de sparkline
class TrendCard extends StatelessWidget {
  const TrendCard({
    required this.title,
    required this.data,
    super.key,
  });

  final String title;
  final List<TimePoint> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final totalWins = data.fold<int>(0, (sum, point) => sum + point.wins);
    final totalGames = data.fold<int>(0, (sum, point) => sum + point.games);
    final avgWinRate = totalGames > 0 ? totalWins / totalGames : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(avgWinRate * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sparkline
            SizedBox(
              height: 60,
              child: CustomPaint(
                painter: _SparklinePainter(
                  data: data,
                  color: Theme.of(context).colorScheme.primary,
                ),
                size: const Size.fromHeight(60),
              ),
            ),

            const SizedBox(height: 8),

            // Statistiques textuelles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  label: 'Parties',
                  value: totalGames.toString(),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                _StatItem(
                  label: 'Victoires',
                  value: totalWins.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'Meilleur jour',
                  value: _getBestDayWinRate(),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getBestDayWinRate() {
    if (data.isEmpty) return '--';

    var bestRate = 0.0;
    for (final point in data) {
      if (point.games > 0) {
        final rate = point.winRate;
        if (rate > bestRate) {
          bestRate = rate;
        }
      }
    }

    return bestRate > 0 ? '${(bestRate * 100).toStringAsFixed(1)}%' : '--';
  }
}

/// Widget pour afficher une statistique individuelle
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Painter personnalisé pour dessiner la sparkline
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.data,
    required this.color,
  });

  final List<TimePoint> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Calculer les valeurs min/max pour normaliser
    double maxWinRate = 0;
    double minWinRate = 1;

    for (final point in data) {
      if (point.games > 0) {
        final rate = point.winRate;
        maxWinRate = maxWinRate > rate ? maxWinRate : rate;
        minWinRate = minWinRate < rate ? minWinRate : rate;
      }
    }

    // Si tous les points sont à 0, pas de graphique
    if (maxWinRate == 0) return;

    // Ajuster l'échelle pour mieux voir les variations
    final range = maxWinRate - minWinRate;
    if (range < 0.1) {
      // Si la variation est faible, centrer autour de la moyenne
      final center = (maxWinRate + minWinRate) / 2;
      minWinRate = (center - 0.05).clamp(0.0, 1.0);
      maxWinRate = (center + 0.05).clamp(0.0, 1.0);
    }

    // Créer les points de la courbe
    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (data.length - 1);

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i * stepX;

      double y;
      if (point.games == 0) {
        // Pas de données pour ce jour
        y = size.height;
      } else {
        final normalizedRate = maxWinRate > minWinRate
            ? (point.winRate - minWinRate) / (maxWinRate - minWinRate)
            : 0.5;
        y = size.height - (normalizedRate * size.height);
      }

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Fermer le chemin de remplissage
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Dessiner le remplissage puis la ligne
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Dessiner des points pour chaque jour avec des données
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      if (point.games > 0) {
        final x = i * stepX;
        final normalizedRate = maxWinRate > minWinRate
            ? (point.winRate - minWinRate) / (maxWinRate - minWinRate)
            : 0.5;
        final y = size.height - (normalizedRate * size.height);

        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
