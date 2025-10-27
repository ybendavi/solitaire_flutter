import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';

/// Provider pour le GameRepository
final gameRepositoryProvider = Provider<GameRepository>((ref) {
  throw UnimplementedError(
      'gameRepositoryProvider must be overridden in main()');
});

/// Repository for managing game state persistence
class GameRepository {
  static const String _boxName = 'game_state';
  static const String _currentGameKey = 'current_game';

  Box<GameState>? _box;

  /// Initialize the repository and open the Hive box
  Future<void> initialize() async {
    _box = await Hive.openBox<GameState>(_boxName);
  }

  /// Save the current game state
  Future<void> saveGame(GameState gameState) async {
    if (_box == null) {
      throw StateError(
          'GameRepository not initialized. Call initialize() first.');
    }

    await _box!.put(_currentGameKey, gameState);
  }

  /// Load the current game state
  /// Returns null if no saved game exists
  GameState? loadGame() {
    if (_box == null) {
      throw StateError(
          'GameRepository not initialized. Call initialize() first.');
    }

    return _box!.get(_currentGameKey);
  }

  /// Check if a saved game exists
  bool hasSavedGame() {
    if (_box == null) {
      throw StateError(
          'GameRepository not initialized. Call initialize() first.');
    }

    return _box!.containsKey(_currentGameKey);
  }

  /// Clear the saved game
  Future<void> clearSavedGame() async {
    if (_box == null) {
      throw StateError(
          'GameRepository not initialized. Call initialize() first.');
    }

    await _box!.delete(_currentGameKey);
  }

  /// Close the repository
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
