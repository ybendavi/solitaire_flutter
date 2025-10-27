import 'dart:math';

/// Générateur de nombres aléatoires avec graine
class SeededRandom {
  SeededRandom([int? seed]) : _random = Random(seed);

  final Random _random;

  int nextInt(int max) => _random.nextInt(max);
  double nextDouble() => _random.nextDouble();
  bool nextBool() => _random.nextBool();

  /// Mélange une liste
  void shuffle<T>(List<T> list) => list.shuffle(_random);
}

/// Utilitaires pour les durées
class DurationUtils {
  /// Formate une durée en chaîne lisible
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Formate une durée en format court (mm:ss)
  static String formatShort(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Parse une chaîne en durée
  static Duration? parse(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return Duration(minutes: minutes, seconds: seconds);
      }
    } catch (e) {
      // Ignore les erreurs de parsing
    }
    return null;
  }
}

/// Utilitaires pour les nombres
class NumberUtils {
  /// Formate un nombre avec des séparateurs de milliers
  static String formatWithCommas(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  /// Clamp un nombre entre min et max
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Calcule un pourcentage
  static double percentage(num value, num total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Arrondit à n décimales
  static double roundToDecimal(double value, int decimals) {
    final factor = pow(10, decimals);
    return (value * factor).round() / factor;
  }
}

/// Utilitaires pour les listes
class ListUtils {
  /// Déplace un élément d'un index à un autre
  static List<T> moveItem<T>(List<T> list, int from, int to) {
    final newList = [...list];
    final item = newList.removeAt(from);
    newList.insert(to, item);
    return newList;
  }

  /// Mélange une liste et retourne une nouvelle liste
  static List<T> shuffled<T>(List<T> list, [Random? random]) {
    final newList = [...list];
    newList.shuffle(random);
    return newList;
  }

  /// Groupe les éléments par une clé
  static Map<K, List<T>> groupBy<T, K>(
      Iterable<T> iterable, K Function(T) keyFunction) {
    final map = <K, List<T>>{};
    for (final item in iterable) {
      final key = keyFunction(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Trouve le premier élément qui satisfait la condition
  static T? firstWhereOrNull<T>(Iterable<T> iterable, bool Function(T) test) {
    for (final item in iterable) {
      if (test(item)) return item;
    }
    return null;
  }
}
