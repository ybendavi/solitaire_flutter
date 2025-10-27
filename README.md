# 🃏 Solitaire Klondike

A beautifully crafted Flutter implementation of the classic Klondike Solitaire card game, featuring smooth animations, comprehensive statistics tracking, and a polished Material Design 3 interface.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-web%20%7C%20windows%20%7C%20android%20%7C%20ios-green.svg)

*[Version française ci-dessous / French version below](#version-française)*

## ✨ Features

### 🎮 Game Features
- **Classic Klondike Rules**: Traditional solitaire gameplay with proper card stacking rules
- **Smooth Card Movement**: Intuitive drag-and-drop interface with visual feedback
- **Auto-Move System**: Automatic and manual card placement to foundations with smart detection
- **Victory Animation**: Celebratory confetti animation upon game completion using CustomPainter
- **Card Flipping**: Automatic tableau card flipping with smooth animations

### 📊 Statistics & Progress
- **Game Statistics**: Track wins, losses, win rate, and game duration
- **Persistent Storage**: All stats saved locally using Hive database
- **Performance Metrics**: Monitor your improvement over time
- **Session Tracking**: Detailed game history and analytics

### 🎨 User Experience
- **Material Design 3**: Modern, responsive UI following Google's latest design principles
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Internationalization**: Full support for English and French languages
- **Cross-Platform**: Runs seamlessly on web, mobile, and desktop platforms
- **Responsive Layout**: Optimized for various screen sizes and orientations

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/solitaire-klondike.git
   cd solitaire-klondike
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate localization files**
   ```bash
   flutter gen-l10n
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Building for Production

#### Web
```bash
flutter build web --release
```

#### Other Platforms
For mobile and desktop platforms, you'll need to add platform-specific configurations:

```bash
# Add platform support first
flutter create --platforms=windows,android,ios,macos,linux .

# Then build for specific platforms
flutter build windows --release  # Windows
flutter build apk --release      # Android
flutter build ios --release      # iOS (requires macOS)
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

## 🏗️ Architecture

### State Management
- **Riverpod**: Modern, compile-safe state management solution
- **Provider Pattern**: Clean separation of business logic and UI
- **Immutable State**: Ensures predictable state updates and debugging

### Project Structure
```
lib/
├── app.dart                    # Main app configuration
├── main.dart                   # Application entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart     # Material Design 3 theme
│   └── utils/
│       ├── settings_service.dart  # App settings management
│       └── utils.dart         # Common utilities
├── features/
│   └── solitaire/
│       ├── data/              # Data layer (repositories, models)
│       ├── domain/            # Business logic (entities, services)
│       └── presentation/      # UI layer (pages, widgets, providers)
├── generated/                 # Auto-generated localization files
└── l10n/                     # Localization resources
```

### Key Components

#### GameController
Central state management for game logic, handling:
- Card movement validation
- Game state transitions  
- Statistics tracking
- Victory detection

#### Card System
- **Immutable Cards**: Each card has a unique ID and immutable properties
- **Pile Management**: Separate management for stock, waste, tableau, and foundation piles
- **Movement Validation**: Comprehensive rules enforcement for valid moves

#### Animation System
- **Physics-Based**: Realistic card movement with proper easing
- **Victory Celebration**: Confetti animation using CustomPainter
- **Smooth Transitions**: Optimized animations for 60fps performance

## 🎯 Game Rules

### Objective
Move all cards to the four foundation piles, organized by suit from Ace to King.

### Gameplay
1. **Tableau**: Seven columns with cards face-down and the top card face-up
2. **Stock**: Remaining cards that can be dealt to the waste pile
3. **Waste**: Cards dealt from stock, top card available for play
4. **Foundation**: Four piles where cards are built up by suit (A, 2, 3... K)

### Valid Moves
- **Tableau to Tableau**: Descending rank, alternating colors
- **Tableau to Foundation**: Ascending rank, same suit
- **Waste to Tableau/Foundation**: Following the same rules
- **Foundation to Tableau**: Descending rank, alternating colors (if needed)

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter integration_test
```

### Test Coverage
- **Unit Tests**: Game rules validation, stats repository
- **Widget Tests**: Victory overlay, stats widgets behavior
- **Integration Tests**: Card dealing animation, game flow scenarios

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Web | ✅ Fully Supported | PWA ready, responsive design |
| Windows | 🚧 Configurable | Requires platform setup |
| Android | 🚧 Configurable | Requires platform setup |
| iOS | 🚧 Configurable | Requires platform setup |
| macOS | 🚧 Configurable | Requires platform setup |
| Linux | 🚧 Configurable | Requires platform setup |

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Dart/Flutter style guidelines
- Maintain test coverage above 80%
- Update documentation for new features
- Ensure cross-platform compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

# Version Française

## 🎮 Fonctionnalités

### Jeu Principal
- **Règles Klondike complètes** : implémentation fidèle du solitaire classique
- **Interface intuitive** : glisser-déposer avec retour visuel immédiat  
- **Système d'auto-move** : placement automatique et manuel des cartes vers les fondations avec détection intelligente
- **Animation de victoire** : célébration avec confettis personnalisés (CustomPainter) lors de la réussite
- **Retournement automatique** : cartes du tableau révélées automatiquement avec animations fluides

### Interface & Accessibilité
- **Material Design 3** : interface moderne et responsive
- **Thèmes adaptatifs** : clair/sombre selon les préférences système
- **Multiplateforme** : web, mobile et desktop
- **Localisation** : français et anglais complets
- **Disposition responsive** : optimisé pour toutes les tailles d'écran

### Données & Persistance  
- **Statistiques détaillées** : victoires, défaites, taux de réussite, durée
- **Sauvegarde locale** : toutes les stats préservées avec Hive
- **Métriques de performance** : suivi de progression dans le temps
- **Historique de session** : historique détaillé des parties

## 🏗️ Architecture

### Gestion d'État
- **Riverpod** : solution moderne et type-safe pour la gestion d'état
- **Pattern Provider** : séparation propre entre logique métier et UI
- **État immutable** : mises à jour d'état prévisibles et débogage facilité

### Structure du Projet
```
lib/
├── app.dart                    # Configuration principale de l'app
├── main.dart                   # Point d'entrée de l'application
├── core/
│   ├── theme/
│   │   └── app_theme.dart     # Thème Material Design 3
│   └── utils/
│       ├── settings_service.dart  # Gestion des paramètres
│       └── utils.dart         # Utilitaires communs
├── features/
│   └── solitaire/
│       ├── data/              # Couche données (repositories, modèles)
│       ├── domain/            # Logique métier (entités, services)
│       └── presentation/      # Couche UI (pages, widgets, providers)
├── generated/                 # Fichiers de localisation générés
└── l10n/                     # Ressources de localisation
```

### Composants Clés

#### GameController
Gestion centralisée de l'état du jeu :
- Validation des mouvements de cartes
- Transitions d'état du jeu
- Suivi des statistiques
- Détection de victoire

#### Système de Cartes
- **Cartes immutables** : chaque carte a un ID unique et des propriétés immutables
- **Gestion des piles** : gestion séparée pour stock, défausse, tableau et fondations
- **Validation des mouvements** : application stricte des règles pour les mouvements valides

#### Système d'Animation
- **Basé sur la physique** : mouvements réalistes avec courbes d'accélération appropriées
- **Célébration de victoire** : animation de confettis avec CustomPainter
- **Transitions fluides** : animations optimisées à 60fps

## � Installation

### Prérequis
- Flutter SDK 3.0 ou supérieur
- Dart SDK 3.0 ou supérieur

### Installation

1. **Cloner le repository**
   ```bash
   git clone https://github.com/votreusername/solitaire-klondike.git
   cd solitaire-klondike
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Générer les fichiers de localisation**
   ```bash
   flutter gen-l10n
   ```

4. **Lancer l'application**
   ```bash
   flutter run
   ```

### Build pour Production

#### Web
```bash
flutter build web --release
```

#### Windows
```bash
flutter build windows --release
```

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## 🎯 Règles du Jeu

### Objectif
Déplacer toutes les cartes vers les quatre piles de fondation, organisées par couleur de l'As au Roi.

### Déroulement
1. **Tableau** : Sept colonnes avec cartes face cachée et la carte du dessus face visible
2. **Stock** : Cartes restantes qui peuvent être distribuées vers la défausse
3. **Défausse** : Cartes distribuées du stock, carte du dessus disponible pour jouer
4. **Fondation** : Quatre piles où les cartes sont construites par couleur (A, 2, 3... R)

### Mouvements Valides
- **Tableau vers Tableau** : Rang décroissant, couleurs alternées
- **Tableau vers Fondation** : Rang croissant, même couleur
- **Défausse vers Tableau/Fondation** : Mêmes règles
- **Fondation vers Tableau** : Rang décroissant, couleurs alternées (si nécessaire)

## 🧪 Tests

### Lancer les Tests
```bash
# Lancer tous les tests
flutter test

# Lancer avec couverture
flutter test --coverage

# Lancer les tests d'intégration
flutter integration_test
```

### Couverture de Tests
- **Tests unitaires** : Logique de jeu centrale et validation des règles
- **Tests de widgets** : Comportement et interactions des composants UI
- **Tests d'intégration** : Scénarios de jeu de bout en bout

## 📱 Support des Plateformes

| Plateforme | Statut | Notes |
|------------|--------|-------|
| Web | ✅ Entièrement Supporté | Prêt PWA, design responsive |
| Windows | ✅ Entièrement Supporté | Expérience desktop native |
| Android | ✅ Entièrement Supporté | Optimisé Material Design |
| iOS | ✅ Entièrement Supporté | Adaptations style Cupertino |
| macOS | ✅ Entièrement Supporté | Expérience desktop native |
| Linux | ✅ Entièrement Supporté | Intégration GTK |

## 🤝 Contribution

Les contributions sont les bienvenues ! Veuillez lire nos directives de contribution et :

1. Fork le repository
2. Créer une branche feature (`git checkout -b feature/fonctionnalite-geniale`)
3. Commit vos changements (`git commit -m 'Ajouter fonctionnalité géniale'`)
4. Push vers la branche (`git push origin feature/fonctionnalite-geniale`)
5. Ouvrir une Pull Request

### Directives de Développement
- Suivre les directives de style Dart/Flutter
- Maintenir la couverture de tests au-dessus de 80%
- Mettre à jour la documentation pour les nouvelles fonctionnalités
- Assurer la compatibilité multiplateforme

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- Équipe Flutter pour le framework fantastique
- Riverpod pour l'excellente gestion d'état
- Équipe Material Design pour le superbe système de design
- Ressources de cartes à jouer et inspiration design de la communauté

## 📞 Support

Si vous rencontrez des problèmes ou avez des questions :
- Ouvrir une issue sur GitHub
- Consulter la [FAQ](docs/FAQ.md) pour les solutions communes
- Revoir la [documentation](docs/) pour des guides détaillés

---

**Développé avec ❤️ en Flutter**