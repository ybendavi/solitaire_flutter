@echo off
echo Installation de Solitaire Klondike

echo.
echo === Verification des prerequis ===
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERREUR: Flutter n'est pas installe ou pas dans le PATH
    echo Veuillez installer Flutter: https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

echo Flutter trouve!
flutter --version

echo.
echo === Installation des dependances ===
flutter pub get
if %errorlevel% neq 0 (
    echo ERREUR: Echec de l'installation des dependances
    pause
    exit /b 1
)

echo.
echo === Generation des fichiers ===
echo Generation des localisations...
flutter gen-l10n

echo Generation du code Riverpod...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo.
echo === Verification du code ===
echo Analyse statique...
flutter analyze
if %errorlevel% neq 0 (
    echo ATTENTION: Des warnings/erreurs ont ete detectes
)

echo Formatage du code...
dart format --set-exit-if-changed .
if %errorlevel% neq 0 (
    echo Code reformate automatiquement
)

echo.
echo === Tests ===
echo Execution des tests...
flutter test
if %errorlevel% neq 0 (
    echo ERREUR: Des tests ont echoue
)

echo.
echo === Installation terminee ===
echo Vous pouvez maintenant lancer l'application avec:
echo   flutter run
echo.
echo Ou builder pour la production:
echo   flutter build apk --release      (Android)
echo   flutter build web --release      (Web)
echo.
pause