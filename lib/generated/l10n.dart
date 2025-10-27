import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Solitaire Klondike'**
  String get appTitle;

  /// No description provided for @newGame.
  ///
  /// In en, this message translates to:
  /// **'New Game'**
  String get newGame;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @moves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get moves;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hint;

  /// No description provided for @noHintAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hint available'**
  String get noHintAvailable;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @statsError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load statistics'**
  String get statsError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filterPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get filterPeriod;

  /// No description provided for @filterRangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterRangeToday;

  /// No description provided for @filterRange7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get filterRange7Days;

  /// No description provided for @filterRange30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get filterRange30Days;

  /// No description provided for @filterRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get filterRangeAll;

  /// No description provided for @filterDrawMode.
  ///
  /// In en, this message translates to:
  /// **'Draw Mode'**
  String get filterDrawMode;

  /// No description provided for @filterDrawModeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterDrawModeAll;

  /// No description provided for @filterDrawMode1Card.
  ///
  /// In en, this message translates to:
  /// **'1 Card'**
  String get filterDrawMode1Card;

  /// No description provided for @filterDrawMode3Cards.
  ///
  /// In en, this message translates to:
  /// **'3 Cards'**
  String get filterDrawMode3Cards;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

  /// No description provided for @gamesWon.
  ///
  /// In en, this message translates to:
  /// **'Games Won'**
  String get gamesWon;

  /// No description provided for @bestTime.
  ///
  /// In en, this message translates to:
  /// **'Best Time'**
  String get bestTime;

  /// No description provided for @avgTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Time'**
  String get avgTime;

  /// No description provided for @avgMoves.
  ///
  /// In en, this message translates to:
  /// **'Avg Moves'**
  String get avgMoves;

  /// No description provided for @vegasBankroll.
  ///
  /// In en, this message translates to:
  /// **'Vegas Bank'**
  String get vegasBankroll;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @trend7Days.
  ///
  /// In en, this message translates to:
  /// **'7-Day Trend'**
  String get trend7Days;

  /// No description provided for @trend30Days.
  ///
  /// In en, this message translates to:
  /// **'30-Day Trend'**
  String get trend30Days;

  /// No description provided for @recentGames.
  ///
  /// In en, this message translates to:
  /// **'Recent Games'**
  String get recentGames;

  /// No description provided for @gameWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get gameWon;

  /// No description provided for @gameLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get gameLost;

  /// No description provided for @winRateSemantics.
  ///
  /// In en, this message translates to:
  /// **'Win rate: {rate} percent'**
  String winRateSemantics(int rate);

  /// No description provided for @gamesPlayedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Games played: {count}'**
  String gamesPlayedSemantics(int count);

  /// No description provided for @gamesWonSemantics.
  ///
  /// In en, this message translates to:
  /// **'Games won: {count}'**
  String gamesWonSemantics(int count);

  /// No description provided for @bestTimeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Best time: {time}'**
  String bestTimeSemantics(String time);

  /// No description provided for @avgTimeSemantics.
  ///
  /// In en, this message translates to:
  /// **'Average time: {time}'**
  String avgTimeSemantics(String time);

  /// No description provided for @avgMovesSemantics.
  ///
  /// In en, this message translates to:
  /// **'Average moves: {moves}'**
  String avgMovesSemantics(int moves);

  /// No description provided for @vegasBankrollSemantics.
  ///
  /// In en, this message translates to:
  /// **'Vegas bankroll: {amount} dollars'**
  String vegasBankrollSemantics(int amount);

  /// No description provided for @currentStreakSemantics.
  ///
  /// In en, this message translates to:
  /// **'Current win streak: {streak}'**
  String currentStreakSemantics(int streak);

  /// No description provided for @bestStreakSemantics.
  ///
  /// In en, this message translates to:
  /// **'Best win streak: {streak}'**
  String bestStreakSemantics(int streak);

  /// No description provided for @victoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Victory!'**
  String get victoryTitle;

  /// No description provided for @victoryAnnounce.
  ///
  /// In en, this message translates to:
  /// **'Game won'**
  String get victoryAnnounce;

  /// No description provided for @replayButton.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get replayButton;

  /// No description provided for @backToMenuButton.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToMenuButton;

  /// No description provided for @labelTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get labelTime;

  /// No description provided for @labelMoves.
  ///
  /// In en, this message translates to:
  /// **'Moves'**
  String get labelMoves;

  /// No description provided for @labelScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get labelScore;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'fr':
      return SFr();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
