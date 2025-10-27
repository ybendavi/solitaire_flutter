// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class SFr extends S {
  SFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Solitaire Klondike';

  @override
  String get newGame => 'Nouvelle partie';

  @override
  String get continueGame => 'Continuer';

  @override
  String get statistics => 'Statistiques';

  @override
  String get settings => 'Paramètres';

  @override
  String get about => 'À propos';

  @override
  String get moves => 'Coups';

  @override
  String get time => 'Temps';

  @override
  String get score => 'Score';

  @override
  String get undo => 'Annuler';

  @override
  String get redo => 'Refaire';

  @override
  String get hint => 'Indice';

  @override
  String get noHintAvailable => 'Aucun indice disponible';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get refresh => 'Actualiser';

  @override
  String get statsError => 'Impossible de charger les statistiques';

  @override
  String get retry => 'Réessayer';

  @override
  String get filters => 'Filtres';

  @override
  String get filterPeriod => 'Période';

  @override
  String get filterRangeToday => 'Aujourd\'hui';

  @override
  String get filterRange7Days => '7 jours';

  @override
  String get filterRange30Days => '30 jours';

  @override
  String get filterRangeAll => 'Tout';

  @override
  String get filterDrawMode => 'Mode de pioche';

  @override
  String get filterDrawModeAll => 'Tous';

  @override
  String get filterDrawMode1Card => '1 carte';

  @override
  String get filterDrawMode3Cards => '3 cartes';

  @override
  String get winRate => 'Taux de victoire';

  @override
  String get gamesPlayed => 'Parties jouées';

  @override
  String get gamesWon => 'Parties gagnées';

  @override
  String get bestTime => 'Meilleur temps';

  @override
  String get avgTime => 'Temps moyen';

  @override
  String get avgMoves => 'Coups moyens';

  @override
  String get vegasBankroll => 'Banque Vegas';

  @override
  String get currentStreak => 'Série actuelle';

  @override
  String get bestStreak => 'Meilleure série';

  @override
  String get trend7Days => 'Tendance 7 jours';

  @override
  String get trend30Days => 'Tendance 30 jours';

  @override
  String get recentGames => 'Parties récentes';

  @override
  String get gameWon => 'Gagnée';

  @override
  String get gameLost => 'Perdue';

  @override
  String winRateSemantics(int rate) {
    return 'Taux de victoire : $rate pour cent';
  }

  @override
  String gamesPlayedSemantics(int count) {
    return 'Parties jouées : $count';
  }

  @override
  String gamesWonSemantics(int count) {
    return 'Parties gagnées : $count';
  }

  @override
  String bestTimeSemantics(String time) {
    return 'Meilleur temps : $time';
  }

  @override
  String avgTimeSemantics(String time) {
    return 'Temps moyen : $time';
  }

  @override
  String avgMovesSemantics(int moves) {
    return 'Coups moyens : $moves';
  }

  @override
  String vegasBankrollSemantics(int amount) {
    return 'Banque Vegas : $amount dollars';
  }

  @override
  String currentStreakSemantics(int streak) {
    return 'Série de victoires actuelle : $streak';
  }

  @override
  String bestStreakSemantics(int streak) {
    return 'Meilleure série de victoires : $streak';
  }

  @override
  String get victoryTitle => 'Victoire !';

  @override
  String get victoryAnnounce => 'Partie gagnée';

  @override
  String get replayButton => 'Rejouer';

  @override
  String get backToMenuButton => 'Retour au menu';

  @override
  String get labelTime => 'Temps';

  @override
  String get labelMoves => 'Coups';

  @override
  String get labelScore => 'Score';
}
