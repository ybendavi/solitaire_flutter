import 'package:flutter/material.dart';

/// Thème clair de l'application
class AppLightTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E7D32), // Vert pour le tapis de jeu
    ),

    // Couleurs spécifiques au jeu
    extensions: const [
      GameColors.light,
    ],

    // AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),

    // Cards
    cardTheme: const CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Icon Buttons
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Dialogs
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Animations
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Thème sombre de l'application
class AppDarkTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor:
          const Color(0xFF4CAF50), // Vert plus clair pour le thème sombre
      brightness: Brightness.dark,
    ),

    // Couleurs spécifiques au jeu
    extensions: const [
      GameColors.dark,
    ],

    // AppBar
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),

    // Cards
    cardTheme: const CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Icon Buttons
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Dialogs
    dialogTheme: const DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // Animations
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Couleurs spécifiques au jeu de Solitaire
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.tableBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.redSuit,
    required this.blackSuit,
    required this.foundationBackground,
    required this.emptyPileBackground,
    required this.selectedCardBorder,
    required this.hintHighlight,
    required this.stockBackground,
    required this.wasteBackground,
  });

  final Color tableBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color redSuit;
  final Color blackSuit;
  final Color foundationBackground;
  final Color emptyPileBackground;
  final Color selectedCardBorder;
  final Color hintHighlight;
  final Color stockBackground;
  final Color wasteBackground;

  static const GameColors light = GameColors(
    tableBackground: Color(0xFF2E7D32), // Vert foncé pour le tapis
    cardBackground: Color(0xFFFFFFFF), // Blanc pour les cartes
    cardBorder: Color(0xFF757575), // Gris pour les bordures
    redSuit: Color(0xFFD32F2F), // Rouge pour cœur et carreau
    blackSuit: Color(0xFF212121), // Noir pour pique et trèfle
    foundationBackground:
        Color(0xFF1B5E20), // Vert plus foncé pour les fondations
    emptyPileBackground: Color(0xFF4CAF50), // Vert clair pour les espaces vides
    selectedCardBorder: Color(0xFFFF9800), // Orange pour la sélection
    hintHighlight: Color(0xFFFFEB3B), // Jaune pour les indices
    stockBackground: Color(0xFF388E3C), // Vert moyen pour le stock
    wasteBackground: Color(0xFF66BB6A), // Vert clair pour la défausse
  );

  static const GameColors dark = GameColors(
    tableBackground: Color(0xFF1B5E20), // Vert très foncé pour le tapis
    cardBackground: Color(0xFF303030), // Gris foncé pour les cartes
    cardBorder: Color(0xFF616161), // Gris clair pour les bordures
    redSuit: Color(0xFFEF5350), // Rouge plus clair
    blackSuit: Color(0xFFE0E0E0), // Gris clair pour le noir
    foundationBackground:
        Color(0xFF0D2F12), // Vert très foncé pour les fondations
    emptyPileBackground: Color(0xFF2E7D32), // Vert foncé pour les espaces vides
    selectedCardBorder: Color(0xFFFFB74D), // Orange clair pour la sélection
    hintHighlight: Color(0xFFFFF176), // Jaune clair pour les indices
    stockBackground: Color(0xFF2E7D32), // Vert foncé pour le stock
    wasteBackground: Color(0xFF4CAF50), // Vert moyen pour la défausse
  );

  /// Mode Sérénité - Couleurs douces et apaisantes pour une expérience calme
  static const GameColors serenity = GameColors(
    tableBackground: Color(0xFF8FB3B8), // Bleu-gris doux et apaisant
    cardBackground: Color(0xFFFFFBF5), // Blanc cassé chaud
    cardBorder: Color(0xFFB8A88A), // Beige doux
    redSuit: Color(0xFFC17B7B), // Rouge adouci, moins agressif
    blackSuit: Color(0xFF5C5C5C), // Gris doux au lieu de noir pur
    foundationBackground: Color(0xFF7A9E9F), // Bleu-vert doux
    emptyPileBackground: Color(0xFFA8C5C7), // Bleu-gris clair
    selectedCardBorder: Color(0xFFD4A574), // Doré doux
    hintHighlight: Color(0xFFE8D5B7), // Beige clair pour les indices
    stockBackground: Color(0xFF9BB8BA), // Bleu-gris moyen
    wasteBackground: Color(0xFFB5CDCF), // Bleu-gris très clair
  );

  @override
  GameColors copyWith({
    Color? tableBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? redSuit,
    Color? blackSuit,
    Color? foundationBackground,
    Color? emptyPileBackground,
    Color? selectedCardBorder,
    Color? hintHighlight,
    Color? stockBackground,
    Color? wasteBackground,
  }) {
    return GameColors(
      tableBackground: tableBackground ?? this.tableBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      redSuit: redSuit ?? this.redSuit,
      blackSuit: blackSuit ?? this.blackSuit,
      foundationBackground: foundationBackground ?? this.foundationBackground,
      emptyPileBackground: emptyPileBackground ?? this.emptyPileBackground,
      selectedCardBorder: selectedCardBorder ?? this.selectedCardBorder,
      hintHighlight: hintHighlight ?? this.hintHighlight,
      stockBackground: stockBackground ?? this.stockBackground,
      wasteBackground: wasteBackground ?? this.wasteBackground,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;

    return GameColors(
      tableBackground: Color.lerp(tableBackground, other.tableBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      redSuit: Color.lerp(redSuit, other.redSuit, t)!,
      blackSuit: Color.lerp(blackSuit, other.blackSuit, t)!,
      foundationBackground:
          Color.lerp(foundationBackground, other.foundationBackground, t)!,
      emptyPileBackground:
          Color.lerp(emptyPileBackground, other.emptyPileBackground, t)!,
      selectedCardBorder:
          Color.lerp(selectedCardBorder, other.selectedCardBorder, t)!,
      hintHighlight: Color.lerp(hintHighlight, other.hintHighlight, t)!,
      stockBackground: Color.lerp(stockBackground, other.stockBackground, t)!,
      wasteBackground: Color.lerp(wasteBackground, other.wasteBackground, t)!,
    );
  }
}

/// Extension pour accéder facilement aux couleurs du jeu
extension GameColorsExtension on BuildContext {
  GameColors get gameColors => Theme.of(this).extension<GameColors>()!;
}
