import 'dart:math';

// Générateur de pseudos en nouchi ivoirien pour les suggestions et comptes anonymes
abstract final class NouchiGenerator {
  static final _random = Random.secure();

  static const _prefixes = [
    'Gbai', 'Bro', 'Yop', 'Abidjan', 'Cocody', 'Abobo',
    'Plateau', 'Marcory', 'Adjame', 'Attieke', 'Dja', 'Wari',
  ];

  static const _suffixes = [
    'Boy', 'Girl', 'Man', 'Boss', 'King', 'Queen', 'Star',
    'Pro', 'God', 'Vibz', 'Flow', 'Clan', 'Gang', 'Fam',
  ];

  static const _adjectives = [
    'Real', 'Vrai', 'Pure', 'True', 'Cool', 'Hot', 'Fire',
    'Live', 'Wild', 'Grand', 'Top', 'Gold', 'Black',
  ];

  // Génère un pseudo aléatoire style nouchi
  static String generateUsername() {
    final prefix = _prefixes[_random.nextInt(_prefixes.length)];
    final adj = _adjectives[_random.nextInt(_adjectives.length)];
    final num = _random.nextInt(999) + 1;
    return '$prefix$adj$num';
  }

  // Génère un pseudo anonyme avec quartier
  static String generateAnonymousUsername(String? city) {
    final quarter = city ?? 'Abidjan';
    final num = _random.nextInt(99) + 1;
    return 'Gbai_${quarter}_$num';
  }

  // Génère 5 suggestions de pseudos
  static List<String> generateSuggestions(String base) {
    final suggestions = <String>[];
    for (int i = 0; i < 5; i++) {
      final suffix = _suffixes[_random.nextInt(_suffixes.length)];
      final num = _random.nextInt(99) + 1;
      suggestions.add('${base}_$suffix$num');
    }
    return suggestions;
  }
}
