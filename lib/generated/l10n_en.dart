// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Solitaire Klondike';

  @override
  String get newGame => 'New Game';

  @override
  String get continueGame => 'Continue';

  @override
  String get statistics => 'Statistics';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get moves => 'Moves';

  @override
  String get time => 'Time';

  @override
  String get score => 'Score';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get hint => 'Hint';

  @override
  String get noHintAvailable => 'No hint available';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get refresh => 'Refresh';

  @override
  String get statsError => 'Unable to load statistics';

  @override
  String get retry => 'Retry';

  @override
  String get filters => 'Filters';

  @override
  String get filterPeriod => 'Period';

  @override
  String get filterRangeToday => 'Today';

  @override
  String get filterRange7Days => '7 Days';

  @override
  String get filterRange30Days => '30 Days';

  @override
  String get filterRangeAll => 'All Time';

  @override
  String get filterDrawMode => 'Draw Mode';

  @override
  String get filterDrawModeAll => 'All';

  @override
  String get filterDrawMode1Card => '1 Card';

  @override
  String get filterDrawMode3Cards => '3 Cards';

  @override
  String get winRate => 'Win Rate';

  @override
  String get gamesPlayed => 'Games Played';

  @override
  String get gamesWon => 'Games Won';

  @override
  String get bestTime => 'Best Time';

  @override
  String get avgTime => 'Avg Time';

  @override
  String get avgMoves => 'Avg Moves';

  @override
  String get vegasBankroll => 'Vegas Bank';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get trend7Days => '7-Day Trend';

  @override
  String get trend30Days => '30-Day Trend';

  @override
  String get recentGames => 'Recent Games';

  @override
  String get gameWon => 'Won';

  @override
  String get gameLost => 'Lost';

  @override
  String winRateSemantics(int rate) {
    return 'Win rate: $rate percent';
  }

  @override
  String gamesPlayedSemantics(int count) {
    return 'Games played: $count';
  }

  @override
  String gamesWonSemantics(int count) {
    return 'Games won: $count';
  }

  @override
  String bestTimeSemantics(String time) {
    return 'Best time: $time';
  }

  @override
  String avgTimeSemantics(String time) {
    return 'Average time: $time';
  }

  @override
  String avgMovesSemantics(int moves) {
    return 'Average moves: $moves';
  }

  @override
  String vegasBankrollSemantics(int amount) {
    return 'Vegas bankroll: $amount dollars';
  }

  @override
  String currentStreakSemantics(int streak) {
    return 'Current win streak: $streak';
  }

  @override
  String bestStreakSemantics(int streak) {
    return 'Best win streak: $streak';
  }

  @override
  String get victoryTitle => 'Victory!';

  @override
  String get victoryAnnounce => 'Game won';

  @override
  String get replayButton => 'Play Again';

  @override
  String get backToMenuButton => 'Back to Menu';

  @override
  String get labelTime => 'Time';

  @override
  String get labelMoves => 'Moves';

  @override
  String get labelScore => 'Score';
}
