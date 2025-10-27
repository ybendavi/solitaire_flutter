import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/stats_providers.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/stats/filters_bar.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/stats/kpi_grid.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/stats/trend_card.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/stats/recent_sessions_list.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

/// Page des statistiques du jeu
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.statistics),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(statsControllerProvider.notifier).refresh(),
            tooltip: S.of(context)!.refresh,
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator.adaptive(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                S.of(context)!.statsError,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(statsControllerProvider.notifier).refresh(),
                child: Text(S.of(context)!.retry),
              ),
            ],
          ),
        ),
        data: (statsData) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de filtres
                const FiltersBar(),
                const SizedBox(height: 12),

                // Contenu principal
                Expanded(
                  child: ListView(
                    children: [
                      // Grille des KPI
                      KpiGrid(data: statsData),
                      const SizedBox(height: 16),

                      // Tendances
                      if (statsData.trend7.isNotEmpty) ...[
                        TrendCard(
                          title: S.of(context)!.trend7Days,
                          data: statsData.trend7,
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (statsData.trend30.isNotEmpty) ...[
                        TrendCard(
                          title: S.of(context)!.trend30Days,
                          data: statsData.trend30,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Historique des parties récentes
                      if (statsData.recent.isNotEmpty)
                        RecentSessionsList(sessions: statsData.recent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
