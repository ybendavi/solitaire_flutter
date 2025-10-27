import 'package:equatable/equatable.dart';
import 'dart:math' show Random;
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';

/// Types de piles dans le jeu Klondike
enum PileType {
  stock, // Talon
  waste, // Défausse
  foundation, // Fondations (4 piles)
  tableau, // Tableau (7 piles)
}

/// Représente une pile de cartes
class Pile extends Equatable {
  const Pile({
    required this.type,
    required this.cards,
    this.index,
  }); // Index pour les piles multiples (tableau, fondations)

  /// Crée une pile vide
  const Pile.empty(this.type, {this.index}) : cards = const [];

  final PileType type;
  final List<Card> cards;
  final int? index;

  /// Carte du dessus (visible)
  Card? get topCard => cards.isEmpty ? null : cards.last;

  /// Nombre de cartes dans la pile
  int get length => cards.length;

  /// Vérifie si la pile est vide
  bool get isEmpty => cards.isEmpty;

  /// Vérifie si la pile n'est pas vide
  bool get isNotEmpty => cards.isNotEmpty;

  /// Cartes face visible
  List<Card> get faceUpCards => cards.where((card) => card.faceUp).toList();

  /// Cartes face cachée
  List<Card> get faceDownCards => cards.where((card) => !card.faceUp).toList();

  /// Retourne les cartes à partir d'un index donné
  List<Card> cardsFrom(int index) {
    if (index < 0 || index >= cards.length) return [];
    return cards.sublist(index);
  }

  /// Vérifie si une carte peut être ajoutée à cette pile
  bool canAcceptCard(Card card) {
    switch (type) {
      case PileType.foundation:
        return card.canBePlacedOnFoundation(topCard);
      case PileType.tableau:
        return card.canBePlacedOnTableau(topCard);
      case PileType.waste:
        return false; // On ne peut pas placer de cartes sur la défausse
      case PileType.stock:
        return false; // On ne peut pas placer de cartes sur le talon
    }
  }

  /// Vérifie si une séquence de cartes peut être ajoutée
  bool canAcceptCards(List<Card> cardsToAdd) {
    if (cardsToAdd.isEmpty) return false;

    // Pour le tableau, on vérifie que la séquence est valide
    if (type == PileType.tableau) {
      // Vérifie que la première carte peut être placée
      if (!canAcceptCard(cardsToAdd.first)) return false;

      // Vérifie que la séquence est valide (alternance couleur, décroissant)
      for (var i = 1; i < cardsToAdd.length; i++) {
        if (!cardsToAdd[i].canBePlacedOnTableau(cardsToAdd[i - 1])) {
          return false;
        }
      }
      return true;
    }

    // Pour les fondations, on ne peut ajouter qu'une carte à la fois
    if (type == PileType.foundation) {
      return cardsToAdd.length == 1 && canAcceptCard(cardsToAdd.first);
    }

    return false;
  }

  /// Ajoute une carte à la pile
  Pile addCard(Card card) {
    return Pile(
      type: type,
      cards: [...cards, card],
      index: index,
    );
  }

  /// Ajoute plusieurs cartes à la pile
  Pile addCards(List<Card> cardsToAdd) {
    return Pile(
      type: type,
      cards: [...cards, ...cardsToAdd],
      index: index,
    );
  }

  /// Retire une carte du dessus
  Pile removeTopCard() {
    if (isEmpty) return this;
    return Pile(
      type: type,
      cards: cards.sublist(0, cards.length - 1),
      index: index,
    );
  }

  /// Retire plusieurs cartes du dessus
  Pile removeTopCards(int count) {
    if (count <= 0 || count > cards.length) return this;
    return Pile(
      type: type,
      cards: cards.sublist(0, cards.length - count),
      index: index,
    );
  }

  /// Retire les cartes à partir d'un index
  Pile removeCardsFrom(int fromIndex) {
    if (fromIndex < 0 || fromIndex >= cards.length) return this;
    return Pile(
      type: type,
      cards: cards.sublist(0, fromIndex),
      index: index,
    );
  }

  /// Retourne une nouvelle pile avec la carte du dessus retournée
  Pile flipTopCard() {
    if (isEmpty) return this;
    final newCards = [...cards];
    newCards[newCards.length - 1] = newCards.last.flip();
    return Pile(
      type: type,
      cards: newCards,
      index: index,
    );
  }

  /// Mélange les cartes (utilisé pour le stock initial)
  Pile shuffle([int? seed]) {
    final newCards = [...cards];
    if (seed != null) {
      newCards.shuffle(Random(seed));
    } else {
      newCards.shuffle();
    }
    return Pile(
      type: type,
      cards: newCards,
      index: index,
    );
  }

  /// Crée une copie de la pile avec les paramètres modifiés
  Pile copyWith({
    PileType? type,
    List<Card>? cards,
    int? index,
  }) {
    return Pile(
      type: type ?? this.type,
      cards: cards ?? this.cards,
      index: index ?? this.index,
    );
  }

  @override
  List<Object?> get props => [type, cards, index];

  @override
  String toString() {
    final typeStr = type.name;
    final indexStr = index != null ? ' #$index' : '';
    return '$typeStr$indexStr (${cards.length} cards)';
  }
}
