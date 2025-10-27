import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Moteur de layout unique pour positionner piles et cartes de façon responsive
/// et déterministe avec animations fluides, offsets cohérents et ancrage correct.
class BoardLayout {
  BoardLayout(
    this.screenSize,
    EdgeInsets safeArea, {
    this.topBar = 72,
    this.hGap = 12,
    this.vGap = 14,
    double additionalPadding = 16,
  }) : padding = EdgeInsets.only(
          left: safeArea.left + additionalPadding,
          top: safeArea.top + topBar,
          right: safeArea.right + additionalPadding,
          bottom: safeArea.bottom + additionalPadding,
        ) {
    _calculateDimensions();
    _calculateRects();
  }

  /// Padding incluant SafeArea + marges
  final EdgeInsets padding;

  /// Ratio largeur/hauteur d'une carte standard (63/88)
  static const double cardAspect = 63 / 88; // ≈ 0.715

  /// Hauteur réservée pour la barre du haut (AppBar + HUD)
  final double topBar;

  /// Espacement horizontal entre les éléments
  final double hGap;

  /// Espacement vertical entre les éléments
  final double vGap;

  /// Taille de l'écran disponible
  final Size screenSize;

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
    // (cartes face down + au moins quelques cartes face up)
    const minRows = 8.0;

    // Calcul de la largeur de carte optimale
    // Contrainte 1: 7 colonnes avec espacement
    final maxWidthByColumns = (availableWidth - 6 * hGap) / 7;

    // Contrainte 2: hauteur disponible pour le tableau
    final tableauHeight =
        availableHeight - (2 * vGap); // Réserve pour les rangées du haut
    final maxWidthByHeight =
        (tableauHeight / (minRows * 0.27 + 1)) * cardAspect;

    // Prendre le minimum pour respecter les deux contraintes
    cardWidth = math.min(maxWidthByColumns, maxWidthByHeight).clamp(40.0, 90.0);
    cardHeight = cardWidth / cardAspect;

    // Calcul des offsets d'empilement (augmentés pour éviter les chevauchements)
    faceUpOffset = (0.32 * cardHeight).clamp(20.0, 42.0);
    faceDownOffset = (0.22 * cardHeight).clamp(14.0, 32.0);
  }

  void _calculateRects() {
    // Position de base (en haut à gauche de la zone de jeu)
    final baseX = padding.left;
    final baseY = padding.top;

    // Stock: ancré en haut-gauche
    stockRect = Rect.fromLTWH(baseX, baseY, cardWidth, cardHeight);

    // Waste: à droite du stock avec espacement
    wasteRect = Rect.fromLTWH(
      stockRect.right + hGap,
      baseY,
      cardWidth,
      cardHeight,
    );

    // Fondations: 4 cases alignées en haut-droite
    foundationRects = List.generate(4, (index) {
      final rightmostX = screenSize.width - padding.right - cardWidth;
      final x = rightmostX - (3 - index) * (cardWidth + hGap);
      return Rect.fromLTWH(x, baseY, cardWidth, cardHeight);
    });

    // Tableau: 7 colonnes sous la rangée du haut
    final tableauY = baseY + cardHeight + vGap;
    final tableauWidth = screenSize.width - padding.horizontal;
    final columnWidth = (tableauWidth - 6 * hGap) / 7;

    tableauColumnRects = List.generate(7, (index) {
      final x = baseX + index * (columnWidth + hGap);
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
    const fanOffset = 24.0;

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

    // Vérifier le stock
    if (stockRect.contains(localPosition)) {
      return DropZone.stock;
    }

    // Vérifier la waste
    if (wasteRect.contains(localPosition)) {
      return DropZone.waste;
    }

    // Vérifier les fondations
    for (var i = 0; i < foundationRects.length; i++) {
      if (foundationRects[i].contains(localPosition)) {
        return DropZone.foundation(i);
      }
    }

    // Vérifier les colonnes du tableau
    for (var i = 0; i < tableauColumnRects.length; i++) {
      // Étendre la zone de drop verticalement pour faciliter le drop
      final extendedRect = tableauColumnRects[i].inflate(8);
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
