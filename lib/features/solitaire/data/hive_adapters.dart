import 'package:hive_flutter/hive_flutter.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/card.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/pile.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/game_state.dart';
import 'package:solitaire_klondike/features/solitaire/domain/entities/move.dart';
import 'package:solitaire_klondike/features/solitaire/data/models/stats_models.dart'
    as stats;

/// Enregistre tous les adapters Hive nécessaires
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SuitAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(RankAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CardAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(PileTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(PileAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(DrawModeAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(GameStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(MoveAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(ScoringModeAdapter());
  }
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(DurationAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(GameStateAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(MoveTypeAdapter());
  }

  // Adapters pour les statistiques
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(StatsDrawModeAdapter());
  }
  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(GameSessionAdapter());
  }
  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(StatsTotalsAdapter());
  }
}

/// Adaptateurs Hive pour la sérialisation des entités de jeu

// Adaptateur pour Suit
class SuitAdapter extends TypeAdapter<Suit> {
  @override
  final int typeId = 0;

  @override
  Suit read(BinaryReader reader) {
    return Suit.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, Suit obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour Rank
class RankAdapter extends TypeAdapter<Rank> {
  @override
  final int typeId = 1;

  @override
  Rank read(BinaryReader reader) {
    return Rank.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, Rank obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour Card
class CardAdapter extends TypeAdapter<Card> {
  @override
  final int typeId = 2;

  @override
  Card read(BinaryReader reader) {
    return Card(
      suit: reader.read() as Suit,
      rank: reader.read() as Rank,
      faceUp: reader.readBool(),
      id: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Card obj) {
    writer.write(obj.suit);
    writer.write(obj.rank);
    writer.writeBool(obj.faceUp);
    writer.writeString(obj.id);
  }
}

// Adaptateur pour PileType
class PileTypeAdapter extends TypeAdapter<PileType> {
  @override
  final int typeId = 3;

  @override
  PileType read(BinaryReader reader) {
    return PileType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, PileType obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour Pile
class PileAdapter extends TypeAdapter<Pile> {
  @override
  final int typeId = 4;

  @override
  Pile read(BinaryReader reader) {
    return Pile(
      type: reader.read() as PileType,
      cards: reader.readList().cast<Card>(),
      index: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Pile obj) {
    writer.write(obj.type);
    writer.writeList(obj.cards);
    writer.writeInt(obj.index ?? -1);
  }
}

// Adaptateur pour DrawMode
class DrawModeAdapter extends TypeAdapter<DrawMode> {
  @override
  final int typeId = 5;

  @override
  DrawMode read(BinaryReader reader) {
    return DrawMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, DrawMode obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour GameStatus
class GameStatusAdapter extends TypeAdapter<GameStatus> {
  @override
  final int typeId = 6;

  @override
  GameStatus read(BinaryReader reader) {
    return GameStatus.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, GameStatus obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour ScoringMode
class ScoringModeAdapter extends TypeAdapter<ScoringMode> {
  @override
  final int typeId = 8;

  @override
  ScoringMode read(BinaryReader reader) {
    return ScoringMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ScoringMode obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour Duration
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 9;

  @override
  Duration read(BinaryReader reader) {
    return Duration(microseconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}

// Adaptateur pour GameState
class GameStateAdapter extends TypeAdapter<GameState> {
  @override
  final int typeId = 10;

  @override
  GameState read(BinaryReader reader) {
    return GameState(
      stock: reader.read() as Pile,
      waste: reader.read() as Pile,
      foundations: reader.readList().cast<Pile>(),
      tableau: reader.readList().cast<Pile>(),
      drawMode: reader.read() as DrawMode,
      status: reader.read() as GameStatus,
      score: reader.readInt(),
      moves: reader.readInt(),
      time: reader.read() as Duration,
      seed: reader.readInt(),
      moveHistory: reader.readList().cast<Move>(),
      redoHistory: reader.readList().cast<Move>(),
      scoringMode: reader.read() as ScoringMode,
      gameNumber: reader.readInt(),
      hintsUsed: reader.readInt(),
      stockTurns: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, GameState obj) {
    writer.write(obj.stock);
    writer.write(obj.waste);
    writer.writeList(obj.foundations);
    writer.writeList(obj.tableau);
    writer.write(obj.drawMode);
    writer.write(obj.status);
    writer.writeInt(obj.score);
    writer.writeInt(obj.moves);
    writer.write(obj.time);
    writer.writeInt(obj.seed);
    writer.writeList(obj.moveHistory);
    writer.writeList(obj.redoHistory);
    writer.write(obj.scoringMode);
    writer.writeInt(obj.gameNumber);
    writer.writeInt(obj.hintsUsed);
    writer.writeInt(obj.stockTurns);
  }
}

// Adaptateur pour MoveType
class MoveTypeAdapter extends TypeAdapter<MoveType> {
  @override
  final int typeId = 11;

  @override
  MoveType read(BinaryReader reader) {
    return MoveType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, MoveType obj) {
    writer.writeByte(obj.index);
  }
}

// Adaptateur pour Move
class MoveAdapter extends TypeAdapter<Move> {
  @override
  final int typeId = 7;

  @override
  Move read(BinaryReader reader) {
    final type = reader.read() as MoveType;
    final from = reader.readInt();
    final to = reader.readInt();
    final cards = reader.readList().cast<Card>();

    return Move(
      type: type,
      from: from,
      to: to,
      cards: cards,
    );
  }

  @override
  void write(BinaryWriter writer, Move obj) {
    writer.write(obj.type);
    writer.writeInt(obj.from);
    writer.writeInt(obj.to ?? -1);
    writer.writeList(obj.cards);
  }
}

/// Adaptateur pour DrawMode des statistiques
class StatsDrawModeAdapter extends TypeAdapter<stats.DrawMode> {
  @override
  final int typeId = 20;

  @override
  stats.DrawMode read(BinaryReader reader) {
    return stats.DrawMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, stats.DrawMode obj) {
    writer.writeByte(obj.index);
  }
}

/// Adaptateur pour GameSession
class GameSessionAdapter extends TypeAdapter<stats.GameSession> {
  @override
  final int typeId = 21;

  @override
  stats.GameSession read(BinaryReader reader) {
    return stats.GameSession(
      id: reader.readString(),
      seed: reader.readInt(),
      drawMode: reader.read() as stats.DrawMode,
      won: reader.readBool(),
      moves: reader.readInt(),
      elapsedMs: reader.readInt(),
      scoreStandard: reader.readInt(),
      scoreVegas: reader.readInt(),
      startedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      endedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      aborted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, stats.GameSession obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.seed);
    writer.write(obj.drawMode);
    writer.writeBool(obj.won);
    writer.writeInt(obj.moves);
    writer.writeInt(obj.elapsedMs);
    writer.writeInt(obj.scoreStandard);
    writer.writeInt(obj.scoreVegas);
    writer.writeInt(obj.startedAt.millisecondsSinceEpoch);
    writer.writeInt(obj.endedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.aborted);
  }
}

/// Adaptateur pour StatsTotals
class StatsTotalsAdapter extends TypeAdapter<stats.StatsTotals> {
  @override
  final int typeId = 22;

  @override
  stats.StatsTotals read(BinaryReader reader) {
    return stats.StatsTotals(
      games: reader.readInt(),
      wins: reader.readInt(),
      sumElapsedMs: reader.readInt(),
      sumMoves: reader.readInt(),
      bestTimeMs: reader.readInt(),
      bestMoves: reader.readInt(),
      vegasBankroll: reader.readInt(),
      currentWinStreak: reader.readInt(),
      bestWinStreak: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, stats.StatsTotals obj) {
    writer.writeInt(obj.games);
    writer.writeInt(obj.wins);
    writer.writeInt(obj.sumElapsedMs);
    writer.writeInt(obj.sumMoves);
    writer.writeInt(obj.bestTimeMs);
    writer.writeInt(obj.bestMoves);
    writer.writeInt(obj.vegasBankroll);
    writer.writeInt(obj.currentWinStreak);
    writer.writeInt(obj.bestWinStreak);
  }
}

/// Initialise tous les adaptateurs Hive
Future<void> initializeHiveAdapters() async {
  await Hive.initFlutter();

  // Enregistrer tous les adaptateurs
  Hive.registerAdapter(SuitAdapter());
  Hive.registerAdapter(RankAdapter());
}
