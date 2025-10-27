import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:solitaire_klondike/app.dart';
import 'package:solitaire_klondike/features/solitaire/data/hive_adapters.dart';
import 'package:solitaire_klondike/features/solitaire/data/repositories/game_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive pour le stockage local
  await Hive.initFlutter();

  // Enregistrer les adapters Hive
  registerHiveAdapters();

  // Initialiser le repository de jeu
  final gameRepository = GameRepository();
  await gameRepository.initialize();

  runApp(
    ProviderScope(
      overrides: [
        gameRepositoryProvider.overrideWithValue(gameRepository),
      ],
      child: const SolitaireApp(),
    ),
  );
}
