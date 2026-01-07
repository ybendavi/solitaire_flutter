import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Taille des cartes pour l'accessibilité seniors
enum CardSize {
  normal,  // Taille standard
  large,   // +20% plus grand
  extraLarge, // +40% plus grand
}

/// Keys for settings storage
class SettingsKeys {
  static const String boxName = 'settings';
  static const String themeMode = 'themeMode';
  static const String drawMode = 'drawMode';
  static const String soundEnabled = 'soundEnabled';
  static const String vibrationEnabled = 'vibrationEnabled';
  static const String autoComplete = 'autoComplete';
  static const String showTimer = 'showTimer';
  static const String leftHandedMode = 'leftHandedMode';
  // Accessibilité seniors
  static const String cardSize = 'cardSize';
  static const String highContrast = 'highContrast';
  static const String plainBackground = 'plainBackground';
  static const String tapToMove = 'tapToMove';
  static const String showScore = 'showScore';
}

/// App settings model
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.drawMode = 1,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoComplete = true,
    this.showTimer = true,
    this.leftHandedMode = false,
    // Accessibilité seniors
    this.cardSize = CardSize.normal,
    this.highContrast = false,
    this.plainBackground = false,
    this.tapToMove = false,
    this.showScore = true,
  });

  final ThemeMode themeMode;
  final int drawMode; // 1 or 3
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoComplete;
  final bool showTimer;
  final bool leftHandedMode;
  // Accessibilité seniors
  final CardSize cardSize;
  final bool highContrast;
  final bool plainBackground;
  final bool tapToMove;
  final bool showScore;

  /// Facteur de mise à l'échelle des cartes selon cardSize
  double get cardSizeMultiplier {
    switch (cardSize) {
      case CardSize.normal:
        return 1.0;
      case CardSize.large:
        return 1.2;
      case CardSize.extraLarge:
        return 1.4;
    }
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? drawMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoComplete,
    bool? showTimer,
    bool? leftHandedMode,
    CardSize? cardSize,
    bool? highContrast,
    bool? plainBackground,
    bool? tapToMove,
    bool? showScore,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      drawMode: drawMode ?? this.drawMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoComplete: autoComplete ?? this.autoComplete,
      showTimer: showTimer ?? this.showTimer,
      leftHandedMode: leftHandedMode ?? this.leftHandedMode,
      cardSize: cardSize ?? this.cardSize,
      highContrast: highContrast ?? this.highContrast,
      plainBackground: plainBackground ?? this.plainBackground,
      tapToMove: tapToMove ?? this.tapToMove,
      showScore: showScore ?? this.showScore,
    );
  }
}

/// Service pour gérer les préférences utilisateur
class SettingsService {
  SettingsService._();

  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  Box<dynamic>? _box;

  /// Initialize the settings service
  Future<void> initialize() async {
    _box = await Hive.openBox<dynamic>(SettingsKeys.boxName);
  }

  /// Load settings from storage
  AppSettings loadSettings() {
    if (_box == null) return const AppSettings();

    final themeModeIndex = _box!.get(SettingsKeys.themeMode, defaultValue: 0) as int;
    final themeMode = ThemeMode.values[themeModeIndex.clamp(0, 2)];

    final cardSizeIndex = _box!.get(SettingsKeys.cardSize, defaultValue: 0) as int;
    final cardSize = CardSize.values[cardSizeIndex.clamp(0, CardSize.values.length - 1)];

    return AppSettings(
      themeMode: themeMode,
      drawMode: _box!.get(SettingsKeys.drawMode, defaultValue: 1) as int,
      soundEnabled: _box!.get(SettingsKeys.soundEnabled, defaultValue: true) as bool,
      vibrationEnabled: _box!.get(SettingsKeys.vibrationEnabled, defaultValue: true) as bool,
      autoComplete: _box!.get(SettingsKeys.autoComplete, defaultValue: true) as bool,
      showTimer: _box!.get(SettingsKeys.showTimer, defaultValue: true) as bool,
      leftHandedMode: _box!.get(SettingsKeys.leftHandedMode, defaultValue: false) as bool,
      // Accessibilité seniors
      cardSize: cardSize,
      highContrast: _box!.get(SettingsKeys.highContrast, defaultValue: false) as bool,
      plainBackground: _box!.get(SettingsKeys.plainBackground, defaultValue: false) as bool,
      tapToMove: _box!.get(SettingsKeys.tapToMove, defaultValue: false) as bool,
      showScore: _box!.get(SettingsKeys.showScore, defaultValue: true) as bool,
    );
  }

  /// Save a single setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _box?.put(key, value);
  }

  /// Save theme mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    await saveSetting(SettingsKeys.themeMode, mode.index);
  }

  /// Détecte si l'utilisateur a activé "Réduire les animations" au niveau système
  static bool get reduceMotionEnabled {
    return WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;
  }

  /// Détecte si l'appareil est en mode économie d'énergie
  static bool get lowPowerModeEnabled {
    // Flutter doesn't have a direct API for this
    return false;
  }

  /// Détermine si les animations doivent être désactivées
  static bool get shouldSkipAnimations {
    return reduceMotionEnabled || lowPowerModeEnabled;
  }
}

/// Provider pour le service de settings
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService.instance;
});

/// Provider pour l'état de réduction des animations
final reduceMotionProvider = Provider<bool>((ref) {
  return SettingsService.shouldSkipAnimations;
});

/// StateNotifier pour gérer les settings de façon réactive
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._service) : super(_service.loadSettings());

  final SettingsService _service;

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _service.saveThemeMode(mode);
  }

  void setDrawMode(int mode) {
    state = state.copyWith(drawMode: mode);
    _service.saveSetting(SettingsKeys.drawMode, mode);
  }

  void setSoundEnabled(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _service.saveSetting(SettingsKeys.soundEnabled, enabled);
  }

  void setVibrationEnabled(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
    _service.saveSetting(SettingsKeys.vibrationEnabled, enabled);
  }

  void setAutoComplete(bool enabled) {
    state = state.copyWith(autoComplete: enabled);
    _service.saveSetting(SettingsKeys.autoComplete, enabled);
  }

  void setShowTimer(bool enabled) {
    state = state.copyWith(showTimer: enabled);
    _service.saveSetting(SettingsKeys.showTimer, enabled);
  }

  void setLeftHandedMode(bool enabled) {
    state = state.copyWith(leftHandedMode: enabled);
    _service.saveSetting(SettingsKeys.leftHandedMode, enabled);
  }

  // Accessibilité seniors
  void setCardSize(CardSize size) {
    state = state.copyWith(cardSize: size);
    _service.saveSetting(SettingsKeys.cardSize, size.index);
  }

  void setHighContrast(bool enabled) {
    state = state.copyWith(highContrast: enabled);
    _service.saveSetting(SettingsKeys.highContrast, enabled);
  }

  void setPlainBackground(bool enabled) {
    state = state.copyWith(plainBackground: enabled);
    _service.saveSetting(SettingsKeys.plainBackground, enabled);
  }

  void setTapToMove(bool enabled) {
    state = state.copyWith(tapToMove: enabled);
    _service.saveSetting(SettingsKeys.tapToMove, enabled);
  }

  void setShowScore(bool enabled) {
    state = state.copyWith(showScore: enabled);
    _service.saveSetting(SettingsKeys.showScore, enabled);
  }
}

/// Provider pour les settings réactifs
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return SettingsNotifier(service);
});
