# Roadmap Accessibilite Seniors - Solitaire Klondike

## Objectif
Ameliorer l'application pour une cible senior avec des features de confort, accessibilite et anti-frustration.

---

## Phase 1 : Accessibilite & Lisibilite (IMPLEMENTE)

### Features implementees

| Feature | Status | Description |
|---------|--------|-------------|
| Slider taille des cartes | OK | Normal / Large (+20%) / Extra Large (+40%) - **Default: XL** |
| Mode contraste eleve | OK (setting) | Toggle pret, theme a implementer |
| Fond uni | OK (setting) | Toggle pret, theme a implementer |
| Tap-to-move | OK | Deplacement auto si UN seul coup valide - **Default: ON** |
| Mode Serenite | OK | Bouton dedique dans le menu + theme distinct |

### Fichiers modifies
- `lib/core/utils/settings_service.dart` - Settings: cardSize, serenityMode, tapToMove, etc.
- `lib/core/theme/app_theme.dart` - Palette GameColors.serenity (bleu-gris apaisant)
- `lib/features/solitaire/presentation/layout/board_layout.dart` - Support cardSizeMultiplier
- `lib/features/solitaire/presentation/pages/home_page.dart` - Bouton "Serenity" dans le menu
- `lib/features/solitaire/presentation/pages/settings_page.dart` - UI pour les nouveaux settings
- `lib/features/solitaire/presentation/pages/game_page.dart` - Theme Serenity + tap-to-move
- `lib/features/solitaire/presentation/providers/game_controller.dart` - Methode tapToMoveCard()

### Mode Serenite
- **Bouton dedié** dans le menu principal (icone spa, couleur bleu-gris)
- **Active automatiquement**: masque score, masque timer, desactive sons
- **Theme distinct**: fond bleu-gris doux (#8FB3B8), couleurs adoucies
- **Desactive** quand on lance une partie normale via "New Game"

### A tester
- [ ] Build reussi
- [ ] App se lance sans crash
- [ ] Settings page affiche les nouveaux controles
- [ ] Slider CardSize change effectivement la taille des cartes
- [ ] Tap-to-move fonctionne (deplace si 1 seul coup possible)
- [ ] Masquer score/timer fonctionne dans le HUD

---

## Phase 2 : Confort & Anti-frustration (IMPLEMENTE)

| Feature | Status | Description |
|---------|--------|-------------|
| Undo illimite | OK | Bouton Undo dans AppBar |
| Undo multiple | OK | Appui long = annuler x5 |
| Sauvegarde auto | OK | Existant |
| Auto-complete fin | OK | Bouton >> quand toutes cartes visibles |

### Details implementation
- **Bouton Undo**: Icone fleche dans AppBar, grise si rien a annuler
- **Appui long**: Annule 5 coups d'un coup avec feedback "Undo x5"
- **Auto-complete**: Bouton >> apparait quand stock/waste vides ET toutes cartes face visible
- **Methodes ajoutees**: `undoMultiple(int)`, `canAutoComplete()`, `autoCompleteGame()`

---

## Phase 3 : Aide intelligente douce (A FAIRE)

| Feature | Status | Description |
|---------|--------|-------------|
| Bouton Indice ameliore | A faire | Surligner le coup suggere |
| Indice auto apres inactivite | A faire | Apres X secondes sans action |

---

## Phase 4 : Mode Serenite complet (A FAIRE)

| Feature | Status | Description |
|---------|--------|-------------|
| Implementer highContrast | A faire | Appliquer au theme |
| Implementer plainBackground | A faire | Fond uni sans texture |
| Messages rassurants | A faire | Optionnels, non culpabilisants |

---

## Phase 5 : Themes & Ambiance (A FAIRE)

| Feature | Status | Description |
|---------|--------|-------------|
| Theme Sepia | A faire | Tons chauds reposants |
| Theme Nuit | A faire | Mode sombre doux |
| Dos de cartes contrastes | A faire | Meilleure visibilite |

---

## Phase 6 : Statistiques & Rituels (A FAIRE)

| Feature | Status | Description |
|---------|--------|-------------|
| Partie du jour | A faire | Seed quotidienne fixe |
| Stats simplifiees | A faire | Non culpabilisantes |

---

## Architecture des Settings

```dart
enum CardSize { normal, large, extraLarge }

class AppSettings {
  // Existants
  ThemeMode themeMode;
  int drawMode;
  bool soundEnabled;
  bool vibrationEnabled;
  bool autoComplete;
  bool showTimer;
  bool leftHandedMode;

  // Phase 1 - Accessibilite seniors
  CardSize cardSize;      // Taille des cartes
  bool highContrast;      // Contraste eleve
  bool plainBackground;   // Fond uni
  bool tapToMove;         // Tap = move si 1 seul coup
  bool showScore;         // Afficher le score (Mode Serenite)
}
```

---

## Notes techniques

### Tap-to-move
- Methode `tapToMoveCard()` dans GameController
- Retourne `(bool success, String? message)`
- Ne deplace que si exactement 1 destination valide
- Feedback discret via SnackBar (800ms)

### CardSize Multiplier
- normal = 1.0x
- large = 1.2x
- extraLarge = 1.4x
- Applique aux dimensions min/max dans BoardLayout
