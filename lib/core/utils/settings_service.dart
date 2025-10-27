import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service pour gérer les préférences utilisateur
class SettingsService {
  /// Détecte si l'utilisateur a activé "Réduire les animations" au niveau système
  static bool get reduceMotionEnabled {
    // Flutter n'a pas encore d'API pour détecter reduceMotions
    // Pour l'instant, on utilise disableAnimations comme approximation
    return WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  /// Détecte si l'appareil est en mode économie d'énergie
  static bool get lowPowerModeEnabled {
    // Sur Flutter, il n'y a pas d'API directe pour détecter le mode économie d'énergie
    // On peut utiliser une heuristique basée sur les performances
    return false; // TODO: Implémenter la détection de low power mode
  }

  /// Détermine si les animations doivent être désactivées
  static bool get shouldSkipAnimations {
    return reduceMotionEnabled || lowPowerModeEnabled;
  }
}

/// Provider pour le service de settings
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// Provider pour l'état de réduction des animations
final reduceMotionProvider = Provider<bool>((ref) {
  return SettingsService.shouldSkipAnimations;
});
