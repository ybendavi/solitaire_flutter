import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/stats_providers.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

/// Barre de filtres pour les statistiques
class FiltersBar extends ConsumerWidget {
  const FiltersBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(statsFilterProvider);
    final controller = ref.read(statsControllerProvider.notifier);
    final l10n = S.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filters,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Filtre par période
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.filterPeriod,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Segmented buttons pour les périodes
            SegmentedButton<StatsRange>(
              segments: [
                ButtonSegment<StatsRange>(
                  value: StatsRange.today,
                  label: Text(l10n.filterRangeToday),
                  icon: const Icon(Icons.today),
                ),
                ButtonSegment<StatsRange>(
                  value: StatsRange.week,
                  label: Text(l10n.filterRange7Days),
                  icon: const Icon(Icons.view_week),
                ),
                ButtonSegment<StatsRange>(
                  value: StatsRange.month,
                  label: Text(l10n.filterRange30Days),
                  icon: const Icon(Icons.calendar_month),
                ),
                ButtonSegment<StatsRange>(
                  value: StatsRange.all,
                  label: Text(l10n.filterRangeAll),
                  icon: const Icon(Icons.all_inclusive),
                ),
              ],
              selected: {filter.range},
              onSelectionChanged: (ranges) {
                if (ranges.isNotEmpty) {
                  controller.setRange(ranges.first);
                }
              },
            ),

            const SizedBox(height: 16),

            // Filtre par mode de pioche
            Row(
              children: [
                Icon(
                  Icons.style,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.filterDrawMode,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Segmented buttons pour les modes de pioche
            SegmentedButton<DrawMode?>(
              segments: [
                ButtonSegment<DrawMode?>(
                  value: null,
                  label: Text(l10n.filterDrawModeAll),
                  icon: const Icon(Icons.all_inclusive),
                ),
                ButtonSegment<DrawMode?>(
                  value: DrawMode.draw1,
                  label: Text(l10n.filterDrawMode1Card),
                  icon: const Icon(Icons.looks_one),
                ),
                ButtonSegment<DrawMode?>(
                  value: DrawMode.draw3,
                  label: Text(l10n.filterDrawMode3Cards),
                  icon: const Icon(Icons.looks_3),
                ),
              ],
              selected: {filter.drawMode},
              onSelectionChanged: (modes) {
                controller.setDrawMode(modes.isEmpty ? null : modes.first);
              },
              emptySelectionAllowed: true,
            ),
          ],
        ),
      ),
    );
  }
}
