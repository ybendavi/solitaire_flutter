import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solitaire_klondike/core/theme/app_theme.dart';
import 'package:solitaire_klondike/features/solitaire/presentation/pages/home_page.dart';
import 'package:solitaire_klondike/generated/l10n.dart';

class SolitaireApp extends ConsumerWidget {
  const SolitaireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Solitaire Klondike',

      // Thèmes
      theme: AppLightTheme.theme,
      darkTheme: AppDarkTheme.theme,

      // Localisation
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,

      // Page d'accueil
      home: const HomePage(),

      // Configuration de debug
      debugShowCheckedModeBanner: false,
    );
  }
}
