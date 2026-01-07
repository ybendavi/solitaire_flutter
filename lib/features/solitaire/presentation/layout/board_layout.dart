import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:solitaire_klondike/core/utils/responsive.dart';

/// Moteur de layout unique pour positionner piles et cartes de façon responsive
/// et déterministe avec animations fluides, offsets cohérents et ancrage correct.
/// Supporte portrait et paysage sur tous les types d'appareils.
/// Supporte un multiplicateur de taille pour l'accessibilité seniors.
class BoardLayout {
  BoardLayout(
    this.screenSize,
    EdgeInsets safeArea, {
    double? topBar,
    double? hGap,
    double? vGap,
    double? additionalPadding,
    this.cardSizeMultiplier = 1.0,
  }) : _safeArea = safeArea {
    _responsiveInfo = _createResponsiveInfo();
    _topBar = topBar ?? ResponsiveSpacing.topBar(_responsiveInfo);
    _hGap = hGap ?? ResponsiveSpacing.hGap(_responsiveInfo);
    _vGap = vGap ?? ResponsiveSpacing.vGap(_responsiveInfo);
    _additionalPadding =
        additionalPadding ?? ResponsiveSpacing.padding(_responsiveInfo);

    padding = EdgeInsets.only(
      left: safeArea.left + _additionalPadding,
      top: safeArea.top + _topBar,
      right: safeArea.right + _additionalPadding,
      bottom: safeArea.bottom + _additionalPadding,
    );

    _calculateDimensions();
    _calculateRects();
  }

  /// Crée des infos responsive basées sur la taille d'écran
  ResponsiveInfo _createResponsiveInfo() {
    final orientation = screenSize.width > screenSize.height
        ? ScreenOrientation.landscape
        : ScreenOrientation.portrait;

    final shortestSide = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;

    DeviceType deviceType;
    if (shortestSide < Breakpoints.sm) {
      deviceType = DeviceType.phone;
    } else if (shortestSide < Breakpoints.lg) {
      deviceType = DeviceType.tablet;
    } else {
      deviceType = DeviceType.desktop;
    }

    return ResponsiveInfo(
      screenSize: screenSize,
      orientation: orientation,
      deviceType: deviceType,
      safeArea: _safeArea,
      devicePixelRatio: 1.0,
    );
  }

  final EdgeInsets _safeArea;
  late final ResponsiveInfo _responsiveInfo;
  late final double _topBar;
  late final double _hGap;
  late final double _vGap;
  late final double _additionalPadding;

  /// Multiplicateur pour la taille des cartes (accessibilité seniors)
  /// 1.0 = normal, 1.2 = large, 1.4 = extra large
  final double cardSizeMultiplier;

  /// Padding incluant SafeArea + marges
  late final EdgeInsets padding;

  /// Ratio largeur/hauteur d'une carte standard (63/88)
  static const double cardAspect = 63 / 88; // ≈ 0.715

  /// Hauteur réservée pour la barre du haut (AppBar + HUD)
  double get topBar => _topBar;

  /// Espacement horizontal entre les éléments
  double get hGap => _hGap;

  /// Espacement vertical entre les éléments
  double get vGap => _vGap;

  /// Taille de l'écran disponible
  final Size screenSize;

  /// Infos responsive
  ResponsiveInfo get responsiveInfo => _responsiveInfo;

  /// Est-ce en mode paysage?
  bool get isLandscape => _responsiveInfo.isLandscape;

  /// Dimensions calculées de carte
  late final double cardWidth;
  late final double cardHeight;
  late final double faceUpOffset;
  late final double faceDownOffset;

  /// Rectangles des zones fixes
  late final Rect stockRect;
  late final Rect wasteRect;
  late final List<Rect> foundationRects;
  late final List<Rect> tableauColumnRects;

  void _calculateDimensions() {
    // Zone disponible après padding
    final availableWidth = screenSize.width - padding.horizontal;
    final availableHeight = screenSize.height - padding.vertical;

    // Estimation du nombre minimal de lignes nécessaires pour le tableau
    // En paysage, on a moins de hauteur donc on réduit
    final minRows = isLandscape ? 6.0 : 8.0;

    // Calcul de la largeur de carte optimale
    // Contrainte 1: 7 colonnes avec espacement
    final maxWidthByColumns = (availableWidth - 6 * _hGap) / 7;

    // Contrainte 2: hauteur disponible pour le tableau
    final tableauHeight = availableHeight - (2 * _vGap);
    final maxWidthByHeight =
        (tableauHeight / (minRows * 0.27 + 1)) * cardAspect;

    // Définir les limites min/max selon le type d'appareil
    // Appliquer le multiplicateur d'accessibilité aux dimensions min/max
    final baseMinCardWidth = _responsiveInfo.responsive<double>(
      phone: _responsiveInfo.isSmallPhone ? 32 : 38,
      tablet: 45,
      desktop: 50,
    );

    final baseMaxCardWidth = _responsiveInfo.responsive<double>(
      phone: isLandscape ? 55 : 70,
      tablet: 85,
      desktop: 100,
    );

    // Appliquer le multiplicateur d'accessibilité seniors
    final minCardWidth = baseMinCardWidth * cardSizeMultiplier;
    final maxCardWidth = baseMaxCardWidth * cardSizeMultiplier;

    // Prendre le minimum pour respecter les deux contraintes
    cardWidth =
        math.min(maxWidthByColumns, maxWidthByHeight).clamp(minCardWidth, maxCardWidth);
    cardHeight = cardWidth / cardAspect;

    // Calcul des offsets d'empilement (augmentés pour éviter les chevauchements)
    // En paysage, réduire les offsets pour économiser de l'espace vertical
    final faceUpMultiplier = isLandscape ? 0.26 : 0.32;
    final faceDownMultiplier = isLandscape ? 0.18 : 0.22;

    final minFaceUpOffset = _responsiveInfo.responsive<double>(
      phone: isLandscape ? 14 : 18,
      tablet: 22,
      desktop: 26,
    );

    final maxFaceUpOffset = _responsiveInfo.responsive<double>(
      phone: isLandscape ? 28 : 36,
      tablet: 42,
      desktop: 50,
    );

    faceUpOffset =
        (faceUpMultiplier * cardHeight).clamp(minFaceUpOffset, maxFaceUpOffset);
    faceDownOffset =
        (faceDownMultiplier * cardHeight).clamp(minFaceUpOffset * 0.7, maxFaceUpOffset * 0.7);
  }

  void _calculateRects() {
    // Position de base (en haut à gauche de la zone de jeu)
    final baseX = padding.left;
    final baseY = padding.top;

    // Stock: ancré en haut-gauche
    stockRect = Rect.fromLTWH(baseX, baseY, cardWidth, cardHeight);

    // Waste: à droite du stock avec espacement
    wasteRect = Rect.fromLTWH(
      stockRect.right + _hGap,
      baseY,
      cardWidth,
      cardHeight,
    );

    // Fondations: 4 cases alignées en haut-droite
    foundationRects = List.generate(4, (index) {
      final rightmostX = screenSize.width - padding.right - cardWidth;
      final x = rightmostX - (3 - index) * (cardWidth + _hGap);
      return Rect.fromLTWH(x, baseY, cardWidth, cardHeight);
    });

    // Tableau: 7 colonnes sous la rangée du haut
    final tableauY = baseY + cardHeight + _vGap;
    final tableauWidth = screenSize.width - padding.horizontal;
    final columnWidth = (tableauWidth - 6 * _hGap) / 7;

    tableauColumnRects = List.generate(7, (index) {
      final x = baseX + index * (columnWidth + _hGap);
      return Rect.fromLTWH(x, tableauY, columnWidth, cardHeight);
    });
  }

  /// Position absolue d'une carte dans une colonne du tableau
  Offset cardOffsetInTableau(
    int columnIndex,
    int stackIndex, {
    required bool faceUp,
  }) {
    if (columnIndex < 0 || columnIndex >= tableauColumnRects.length) {
      throw ArgumentError(
        'columnIndex doit être entre 0 et ${tableauColumnRects.length - 1}',
      );
    }

    final baseRect = tableauColumnRects[columnIndex];
    final offset = faceUp ? faceUpOffset : faceDownOffset;

    return Offset(
      baseRect.left +
          (baseRect.width - cardWidth) / 2, // Centre la carte dans la colonne
      baseRect.top + (stackIndex * offset),
    );
  }

  /// Position absolue d'une carte dans la waste (pour affichage en éventail)
  Offset cardOffsetInWaste(int stackIndex) {
    const maxVisible = 3;
    // Ajuster le fan offset selon la taille des cartes
    final fanOffset = cardWidth * 0.35;

    if (stackIndex < maxVisible) {
      return Offset(
        wasteRect.left + (stackIndex * fanOffset),
        wasteRect.top,
      );
    } else {
      // Seules les 3 dernières cartes sont visibles
      final visibleIndex = stackIndex % maxVisible;
      return Offset(
        wasteRect.left + (visibleIndex * fanOffset),
        wasteRect.top,
      );
    }
  }

  /// Rect pour une carte à une position donnée
  Rect cardRectAt(Offset position) {
    return Rect.fromLTWH(position.dx, position.dy, cardWidth, cardHeight);
  }

  /// Détermine sur quelle zone de drop se trouve un point global
  DropZone? getDropZoneAt(Offset globalPosition) {
    // Convertir en coordonnées locales
    final localPosition = globalPosition;

    // Zone d'extension adaptative selon l'appareil
    final dropExtension = _responsiveInfo.responsive<double>(
      phone: 10,
      tablet: 8,
      desktop: 6,
    );

    // Vérifier le stock
    if (stockRect.inflate(dropExtension).contains(localPosition)) {
      return DropZone.stock;
    }

    // Vérifier la waste
    if (wasteRect.inflate(dropExtension).contains(localPosition)) {
      return DropZone.waste;
    }

    // Vérifier les fondations
    for (var i = 0; i < foundationRects.length; i++) {
      if (foundationRects[i].inflate(dropExtension).contains(localPosition)) {
        return DropZone.foundation(i);
      }
    }

    // Vérifier les colonnes du tableau
    for (var i = 0; i < tableauColumnRects.length; i++) {
      // Étendre la zone de drop verticalement pour faciliter le drop
      final extendedRect = tableauColumnRects[i].inflate(dropExtension);
      if (extendedRect.contains(localPosition)) {
        return DropZone.tableau(i);
      }
    }

    return null;
  }

  /// Retourne des informations de debug pour l'affichage
  List<DebugRect> getDebugRects() {
    return [
      DebugRect('Stock', stockRect, Colors.green),
      DebugRect('Waste', wasteRect, Colors.blue),
      ...foundationRects.asMap().entries.map(
            (e) => DebugRect('Foundation ${e.key}', e.value, Colors.red),
          ),
      ...tableauColumnRects.asMap().entries.map(
            (e) => DebugRect('Tableau ${e.key}', e.value, Colors.orange),
          ),
    ];
  }
}

/// Zone de drop possible
sealed class DropZone {
  const DropZone();

  const factory DropZone._stock() = StockDropZone;
  const factory DropZone._waste() = WasteDropZone;
  const factory DropZone._foundation(int index) = FoundationDropZone;
  const factory DropZone._tableau(int index) = TableauDropZone;

  static const stock = DropZone._stock();
  static const waste = DropZone._waste();
  static DropZone foundation(int index) => DropZone._foundation(index);
  static DropZone tableau(int index) => DropZone._tableau(index);
}

class StockDropZone extends DropZone {
  const StockDropZone();
}

class WasteDropZone extends DropZone {
  const WasteDropZone();
}

class FoundationDropZone extends DropZone {
  const FoundationDropZone(this.index);
  final int index;
}

class TableauDropZone extends DropZone {
  const TableauDropZone(this.index);
  final int index;
}

/// Informations pour le debug overlay
class DebugRect {
  const DebugRect(this.label, this.rect, this.color);
  final String label;
  final Rect rect;
  final Color color;
}
