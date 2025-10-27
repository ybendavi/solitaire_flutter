#!/bin/bash

echo "Installation de Solitaire Klondike"

echo ""
echo "=== Vérification des prérequis ==="
if ! command -v flutter &> /dev/null; then
    echo "ERREUR: Flutter n'est pas installé ou pas dans le PATH"
    echo "Veuillez installer Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "Flutter trouvé!"
flutter --version

echo ""
echo "=== Installation des dépendances ==="
flutter pub get
if [ $? -ne 0 ]; then
    echo "ERREUR: Échec de l'installation des dépendances"
    exit 1
fi

echo ""
echo "=== Génération des fichiers ==="
echo "Génération des localisations..."
flutter gen-l10n

echo "Génération du code Riverpod..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo ""
echo "=== Vérification du code ==="
echo "Analyse statique..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "ATTENTION: Des warnings/erreurs ont été détectés"
fi

echo "Formatage du code..."
dart format --set-exit-if-changed .
if [ $? -ne 0 ]; then
    echo "Code reformaté automatiquement"
fi

echo ""
echo "=== Tests ==="
echo "Exécution des tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "ERREUR: Des tests ont échoué"
fi

echo ""
echo "=== Installation terminée ==="
echo "Vous pouvez maintenant lancer l'application avec:"
echo "  flutter run"
echo ""
echo "Ou builder pour la production:"
echo "  flutter build apk --release      (Android)"
echo "  flutter build ipa --release      (iOS)"  
echo "  flutter build web --release      (Web)"
echo ""