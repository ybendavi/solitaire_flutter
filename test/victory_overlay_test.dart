import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/victory_overlay.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/overlay/stats_snapshot.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

void main() {
  group('VictoryOverlay Widget Tests', () {
    testWidgets('VictoryOverlay displays victory panel',
        (WidgetTester tester) async {
      var replayPressed = false;
      var backPressed = false;

      const stats = StatsSnapshot(
        time: Duration(minutes: 2, seconds: 30),
        moves: 100,
        score: 1500,
        scoringMode: ScoringMode.standard,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('fr', ''),
          ],
          home: Scaffold(
            body: VictoryOverlay(
              stats: stats,
              onReplay: () => replayPressed = true,
              onBackToMenu: () => backPressed = true,
            ),
          ),
        ),
      );

      // Permettre aux animations de se lancer
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(
          const Duration(milliseconds: 900)); // Attendre l'affichage du panneau
      await tester.pumpAndSettle();

      // Vérifier que le panneau de victoire est affiché
      expect(find.text('Victory!'), findsOneWidget);
      expect(find.text('Play Again'), findsOneWidget);
      expect(find.text('Back to Menu'), findsOneWidget);

      // Vérifier les statistiques
      expect(find.text('02:30'), findsOneWidget); // Temps formaté
      expect(find.text('100'), findsOneWidget); // Moves
      expect(find.text('1500'), findsOneWidget); // Score

      // Tester les boutons
      await tester.tap(find.text('Play Again'));
      await tester.pump();
      expect(replayPressed, isTrue);

      await tester.tap(find.text('Back to Menu'));
      await tester.pump();
      expect(backPressed, isTrue);
    });

    testWidgets('VictoryOverlay handles Vegas mode correctly',
        (WidgetTester tester) async {
      const stats = StatsSnapshot(
        time: Duration(minutes: 1, seconds: 15),
        moves: 75,
        score: -10,
        scoringMode: ScoringMode.vegas,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('fr', ''),
          ],
          home: Scaffold(
            body: VictoryOverlay(
              stats: stats,
              onReplay: () {},
              onBackToMenu: () {},
            ),
          ),
        ),
      );

      // Permettre aux animations de se lancer
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Vérifier l'affichage du score Vegas avec le symbole $
      expect(find.textContaining(r'-10 $'), findsOneWidget);
    });

    testWidgets('VictoryOverlay is accessible', (WidgetTester tester) async {
      const stats = StatsSnapshot(
        time: Duration(seconds: 45),
        moves: 50,
        score: 800,
        scoringMode: ScoringMode.standard,
      );

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('fr', ''),
          ],
          home: Scaffold(
            body: VictoryOverlay(
              stats: stats,
              onReplay: () {},
              onBackToMenu: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Vérifier les éléments d'accessibilité
      final titleFinder = find.byType(Text).first;
      final titleWidget = tester.widget<Text>(titleFinder);

      // Vérifier que le titre a un semanticsLabel approprié
      expect(titleWidget.semanticsLabel, isNotNull);
    });
  });
}
