import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/providers/stats_providers.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/stats/kpi_grid.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/widgets/stats/trend_card.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

void main() {
  group('Stats Widgets Tests', () {
    testWidgets('KpiGrid affiche les KPI correctement',
        (WidgetTester tester) async {
      const testData = StatsViewModel(
        games: 10,
        wins: 7,
        winRate: 0.7,
        bestTime: Duration(minutes: 2, seconds: 30),
        avgTime: Duration(minutes: 4, seconds: 15),
        avgMoves: 125.5,
        scoreStandardSum: 15000,
        vegasBankroll: 250,
        currentStreak: 3,
        bestStreak: 5,
        trend7: [],
        trend30: [],
        recent: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: KpiGrid(data: testData),
          ),
        ),
      );

      // Vérifier que les KPI sont affichés
      expect(find.text('70.0%'), findsOneWidget); // Win rate
      expect(find.text('10'), findsOneWidget); // Games played
      expect(find.text('7'), findsOneWidget); // Games won
      expect(find.text('2m 30s'), findsOneWidget); // Best time
      expect(find.text('4m 15s'), findsOneWidget); // Avg time
      expect(find.text('125.5'), findsOneWidget); // Avg moves
      expect(find.text(r'+$250'), findsOneWidget); // Vegas bankroll
      expect(find.text('3'), findsOneWidget); // Current streak
      expect(find.text('5'), findsOneWidget); // Best streak

      // Vérifier que les icônes sont présentes
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.casino), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('KpiGrid affiche Vegas bankroll négatif correctement',
        (WidgetTester tester) async {
      const testData = StatsViewModel(
        games: 5,
        wins: 1,
        winRate: 0.2,
        bestTime: Duration(seconds: 45),
        avgTime: Duration(minutes: 1, seconds: 30),
        avgMoves: 85,
        scoreStandardSum: 2000,
        vegasBankroll: -150, // Bankroll négatif
        currentStreak: 0,
        bestStreak: 1,
        trend7: [],
        trend30: [],
        recent: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: KpiGrid(data: testData),
          ),
        ),
      );

      // Vérifier l'affichage du bankroll négatif
      expect(find.text(r'-$150'), findsOneWidget);
    });

    testWidgets('TrendCard affiche la tendance correctement',
        (WidgetTester tester) async {
      final trendData = [
        TimePoint(
          date: DateTime.now().subtract(const Duration(days: 2)),
          wins: 2,
          games: 3,
        ),
        TimePoint(
          date: DateTime.now().subtract(const Duration(days: 1)),
          wins: 1,
          games: 2,
        ),
        TimePoint(
          date: DateTime.now(),
          wins: 3,
          games: 4,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrendCard(
              title: 'Test Trend',
              data: trendData,
            ),
          ),
        ),
      );

      // Vérifier que le titre est affiché
      expect(find.text('Test Trend'), findsOneWidget);

      // Vérifier les statistiques calculées
      expect(find.text('9'), findsOneWidget); // Total games
      expect(find.text('6'), findsOneWidget); // Total wins

      // Vérifier la présence de la sparkline (CustomPaint)
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets("TrendCard n'affiche rien si pas de données",
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrendCard(
              title: 'Empty Trend',
              data: [],
            ),
          ),
        ),
      );

      // Vérifier qu'aucun contenu n'est affiché
      expect(find.text('Empty Trend'), findsNothing);
      expect(find.byType(CustomPaint), findsNothing);
    });

    group('TimePoint', () {
      test('calcule correctement le winRate', () {
        final point1 = TimePoint(
          date: DateTime.now(),
          wins: 3,
          games: 5,
        );
        expect(point1.winRate, equals(0.6));

        final point2 = TimePoint(
          date: DateTime.now(),
          wins: 0,
          games: 0,
        );
        expect(point2.winRate, equals(0.0));

        final point3 = TimePoint(
          date: DateTime.now(),
          wins: 2,
          games: 2,
        );
        expect(point3.winRate, equals(1.0));
      });
    });

    group('StatsFilter', () {
      test('copyWith fonctionne correctement', () {
        const original = StatsFilter(
          range: StatsRange.week,
          drawMode: DrawMode.draw1,
        );

        final copy1 = original.copyWith(range: StatsRange.month);
        expect(copy1.range, equals(StatsRange.month));
        expect(copy1.drawMode, equals(DrawMode.draw1));

        final copy2 = original.copyWith(drawMode: DrawMode.draw3);
        expect(copy2.range, equals(StatsRange.week));
        expect(copy2.drawMode, equals(DrawMode.draw3));
      });

      test('equality fonctionne correctement', () {
        const filter1 = StatsFilter(
          range: StatsRange.today,
          drawMode: DrawMode.draw1,
        );

        const filter2 = StatsFilter(
          range: StatsRange.today,
          drawMode: DrawMode.draw1,
        );

        const filter3 = StatsFilter(
          range: StatsRange.week,
          drawMode: DrawMode.draw1,
        );

        expect(filter1, equals(filter2));
        expect(filter1, isNot(equals(filter3)));
      });
    });

    group('StatsRange extension', () {
      test('startDate retourne les bonnes dates', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        expect(StatsRange.today.startDate, equals(today));
        expect(StatsRange.all.startDate, isNull);

        final weekStart = StatsRange.week.startDate!;
        expect(weekStart.isBefore(now), isTrue);
        expect(now.difference(weekStart).inDays, equals(7));

        final monthStart = StatsRange.month.startDate!;
        expect(monthStart.isBefore(now), isTrue);
        expect(now.difference(monthStart).inDays, equals(30));
      });

      test('key retourne les bonnes clés', () {
        expect(StatsRange.today.key, equals('today'));
        expect(StatsRange.week.key, equals('week'));
        expect(StatsRange.month.key, equals('month'));
        expect(StatsRange.all.key, equals('all'));
      });
    });
  });
}
