import 'package:equatable/equatable.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';

/// Types de mouvements possibles
enum MoveType {
  stockToWaste, // Piocher du talon vers la défausse
  wasteToTableau, // Défausse vers tableau
  wasteToFoundation, // Défausse vers fondation
  tableauToTableau, // Tableau vers tableau
  tableauToFoundation, // Tableau vers fondation
  foundationToTableau, // Fondation vers tableau
  flipTableauCard, // Retourner une carte du tableau
  resetStock, // Remettre la défausse dans le talon
}

/// Représente un mouvement dans le jeu
class Move extends Equatable {
  const Move({
    required this.type,
    required this.from,
    this.to,
    this.cards = const [],
    this.cardCount = 1,
  }); // Nombre de cartes déplacées

  /// Crée un mouvement de pioche du talon
  const Move.stockToWaste({required List<Card> cards})
      : type = MoveType.stockToWaste,
        from = 0,
        to = null,
        cards = cards,
        cardCount = cards.length;

  /// Crée un mouvement de la défausse vers le tableau
  const Move.wasteToTableau({
    required int tableauIndex,
    required Card card,
  })  : type = MoveType.wasteToTableau,
        from = 0,
        to = tableauIndex,
        cards = const [],
        cardCount = 1;

  /// Crée un mouvement de la défausse vers une fondation
  const Move.wasteToFoundation({
    required int foundationIndex,
    required Card card,
  })  : type = MoveType.wasteToFoundation,
        from = 0,
        to = foundationIndex,
        cards = const [],
        cardCount = 1;

  /// Crée un mouvement entre deux piles du tableau
  const Move.tableauToTableau({
    required int fromIndex,
    required int toIndex,
    required List<Card> cards,
  })  : type = MoveType.tableauToTableau,
        from = fromIndex,
        to = toIndex,
        cards = cards,
        cardCount = 1;

  /// Crée un mouvement du tableau vers une fondation
  const Move.tableauToFoundation({
    required int tableauIndex,
    required int foundationIndex,
    required Card card,
  })  : type = MoveType.tableauToFoundation,
        from = tableauIndex,
        to = foundationIndex,
        cards = const [],
        cardCount = 1;

  /// Crée un mouvement d'une fondation vers le tableau
  const Move.foundationToTableau({
    required int foundationIndex,
    required int tableauIndex,
    required Card card,
  })  : type = MoveType.foundationToTableau,
        from = foundationIndex,
        to = tableauIndex,
        cards = const [],
        cardCount = 1;

  /// Crée un mouvement de retournement de carte
  const Move.flipTableauCard({
    required int tableauIndex,
    required Card card,
  })  : type = MoveType.flipTableauCard,
        from = tableauIndex,
        to = null,
        cards = const [],
        cardCount = 1;

  /// Crée un mouvement de remise à zéro du talon
  const Move.resetStock({required List<Card> cards})
      : type = MoveType.resetStock,
        from = 0,
        to = null,
        cards = cards,
        cardCount = 1;

  final MoveType type;
  final int from; // Index de la pile source
  final int? to; // Index de la pile destination (null pour certains mouvements)
  final List<Card> cards; // Cartes déplacées (pour l'historique)
  final int cardCount;

  /// Vérifie si le mouvement est un déplacement de cartes
  bool get isCardMove {
    return type != MoveType.flipTableauCard &&
        type != MoveType.resetStock &&
        type != MoveType.stockToWaste;
  }

  /// Vérifie si le mouvement concerne le tableau
  bool get involvesTableau {
    return type == MoveType.wasteToTableau ||
        type == MoveType.tableauToTableau ||
        type == MoveType.tableauToFoundation ||
        type == MoveType.foundationToTableau ||
        type == MoveType.flipTableauCard;
  }

  /// Vérifie si le mouvement concerne les fondations
  bool get involvesFoundation {
    return type == MoveType.wasteToFoundation ||
        type == MoveType.tableauToFoundation ||
        type == MoveType.foundationToTableau;
  }

  /// Crée une copie du mouvement avec les paramètres modifiés
  Move copyWith({
    MoveType? type,
    int? from,
    int? to,
    List<Card>? cards,
    int? cardCount,
  }) {
    return Move(
      type: type ?? this.type,
      from: from ?? this.from,
      to: to ?? this.to,
      cards: cards ?? this.cards,
      cardCount: cardCount ?? this.cardCount,
    );
  }

  @override
  List<Object?> get props => [type, from, to, cards, cardCount];

  @override
  String toString() {
    switch (type) {
      case MoveType.stockToWaste:
        return 'Stock → Waste';
      case MoveType.wasteToTableau:
        return 'Waste → Tableau $to';
      case MoveType.wasteToFoundation:
        return 'Waste → Foundation $to';
      case MoveType.tableauToTableau:
        return 'Tableau $from → Tableau $to';
      case MoveType.tableauToFoundation:
        return 'Tableau $from → Foundation $to';
      case MoveType.foundationToTableau:
        return 'Foundation $from → Tableau $to';
      case MoveType.flipTableauCard:
        return 'Flip Tableau $from';
      case MoveType.resetStock:
        return 'Reset Stock';
    }
  }
}
