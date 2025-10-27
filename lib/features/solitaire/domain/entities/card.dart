import 'package:equatable/equatable.dart';

/// Représente les couleurs des cartes (Rouge/Noir)
enum CardColor { red, black }

/// Représente les enseignes des cartes
enum Suit {
  spades(color: CardColor.black, symbol: '♠'),
  hearts(color: CardColor.red, symbol: '♥'),
  diamonds(color: CardColor.red, symbol: '♦'),
  clubs(color: CardColor.black, symbol: '♣');

  const Suit({required this.color, required this.symbol});

  final CardColor color;
  final String symbol;
}

/// Représente les rangs des cartes (As à Roi)
enum Rank {
  ace(value: 1, symbol: 'A'),
  two(value: 2, symbol: '2'),
  three(value: 3, symbol: '3'),
  four(value: 4, symbol: '4'),
  five(value: 5, symbol: '5'),
  six(value: 6, symbol: '6'),
  seven(value: 7, symbol: '7'),
  eight(value: 8, symbol: '8'),
  nine(value: 9, symbol: '9'),
  ten(value: 10, symbol: '10'),
  jack(value: 11, symbol: 'J'),
  queen(value: 12, symbol: 'Q'),
  king(value: 13, symbol: 'K');

  const Rank({required this.value, required this.symbol});

  final int value;
  final String symbol;

  /// Retourne le rang précédent (pour les piles décroissantes)
  Rank? get previous {
    if (this == ace) return null;
    return Rank.values[index - 1];
  }

  /// Retourne le rang suivant (pour les fondations croissantes)
  Rank? get next {
    if (this == king) return null;
    return Rank.values[index + 1];
  }
}

/// Représente une carte de jeu
class Card extends Equatable {
  const Card({
    required this.suit,
    required this.rank,
    required this.faceUp,
    String? id,
  }) : id = id ?? '';

  final Suit suit;
  final Rank rank;
  final bool faceUp;
  final String id;

  /// Couleur de la carte (rouge/noir)
  CardColor get color => suit.color;

  /// Valeur numérique de la carte
  int get value => rank.value;

  /// Représentation textuelle de la carte
  String get displayName => '${rank.symbol}${suit.symbol}';

  /// Vérifie si cette carte peut être placée sur une autre dans le tableau
  /// (alternance de couleur et rang décroissant)
  bool canBePlacedOnTableau(Card? other) {
    if (other == null) {
      final canPlace = rank == Rank.king;
      print(
        '[Card] Can place ${rank.symbol}${suit.symbol} on empty pile: $canPlace (must be King)',
      );
      return canPlace;
    }
    final colorOk = color != other.color;
    final rankOk = rank.value == other.rank.value - 1;
    final canPlace = colorOk && rankOk;
    print(
      '[Card] Can place ${rank.symbol}${suit.symbol} (${color.name}, ${rank.value}) on ${other.rank.symbol}${other.suit.symbol} (${other.color.name}, ${other.rank.value}): $canPlace (colorOk: $colorOk, rankOk: $rankOk)',
    );
    return canPlace;
  }

  /// Vérifie si cette carte peut être placée sur une fondation
  /// (même enseigne et rang croissant)
  bool canBePlacedOnFoundation(Card? other) {
    if (other == null) {
      final canPlace = rank == Rank.ace;
      print(
        '[Card] Can place ${rank.symbol}${suit.symbol} on empty foundation: $canPlace (must be Ace)',
      );
      return canPlace;
    }
    final suitOk = suit == other.suit;
    final rankOk = rank.value == other.rank.value + 1;
    final canPlace = suitOk && rankOk;
    print(
      '[Card] Can place ${rank.symbol}${suit.symbol} (${suit.name}, ${rank.value}) on foundation ${other.rank.symbol}${other.suit.symbol} (${other.suit.name}, ${other.rank.value}): $canPlace (suitOk: $suitOk, rankOk: $rankOk)',
    );
    return canPlace;
  }

  /// Crée une copie de la carte avec les paramètres modifiés
  Card copyWith({
    Suit? suit,
    Rank? rank,
    bool? faceUp,
    String? id,
  }) {
    return Card(
      suit: suit ?? this.suit,
      rank: rank ?? this.rank,
      faceUp: faceUp ?? this.faceUp,
      id: id ?? this.id,
    );
  }

  /// Retourne une carte face visible
  Card flip() => copyWith(faceUp: !faceUp);

  @override
  List<Object?> get props => [suit, rank, faceUp, id];

  @override
  String toString() => '$displayName${faceUp ? '' : ' (hidden)'}';
}
