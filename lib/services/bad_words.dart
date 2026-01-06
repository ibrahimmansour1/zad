/// Bad words filter utility
/// Filters inappropriate content before posting
library;

class BadWordsFilter {
  /// List of bad words to filter
  /// Comprehensive list covering multiple languages
  static const List<String> _badWords = [
    // English bad words
    'fuck', 'shit', 'damn', 'ass', 'bitch', 'bastard',
    'crap', 'idiot', 'stupid', 'dumb', 'moron',
    'jerk', 'loser', 'suck', 'whore', 'slut',

    // Arabic bad words (common offensive terms)
    'كلب', 'حمار', 'غبي', 'أحمق', 'تافه', 'وقح',
    'سافل', 'منحط', 'قذر', 'لعنة', 'خنزير', 'حقير',
    'نجس', 'كافر', 'منافق', 'فاسق', 'زنديق', 'ملعون',
    'عاهرة', 'زانية', 'فاجرة', 'لص', 'كذاب', 'مجرم',
    'خائن', 'جبان', 'ذليل', 'وضيع', 'دنيء', 'رذيل',

    // Spanish bad words
    'mierda', 'puta', 'pendejo', 'idiota', 'estupido',

    // Portuguese bad words
    'merda', 'porra', 'burro', 'idiota',

    // French bad words
    'merde', 'putain', 'con', 'idiot', 'stupide',

    // Filipino bad words
    'gago', 'tanga', 'bobo', 'ulol',
  ];

  /// Characters used to replace bad words
  static const String _replacementChar = '*';

  /// Filter bad words from input text
  /// Returns the filtered string with bad words replaced by asterisks
  static String filterBadWords(String input) {
    if (input.isEmpty) return input;

    String result = input;

    for (final word in _badWords) {
      // Create case-insensitive pattern with word boundaries
      final pattern = RegExp(
        r'\b' + RegExp.escape(word) + r'\b',
        caseSensitive: false,
        unicode: true,
      );

      result = result.replaceAllMapped(pattern, (match) {
        // Replace with asterisks of same length
        return _replacementChar * match.group(0)!.length;
      });
    }

    return result;
  }

  /// Check if text contains any bad words
  /// Returns true if bad words are found
  static bool containsBadWords(String input) {
    if (input.isEmpty) return false;

    for (final word in _badWords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(word) + r'\b',
        caseSensitive: false,
        unicode: true,
      );

      if (pattern.hasMatch(input)) {
        return true;
      }
    }

    return false;
  }

  /// Get list of bad words found in text
  /// Useful for moderation/logging
  static List<String> findBadWords(String input) {
    if (input.isEmpty) return [];

    final foundWords = <String>[];

    for (final word in _badWords) {
      final pattern = RegExp(
        r'\b' + RegExp.escape(word) + r'\b',
        caseSensitive: false,
        unicode: true,
      );

      if (pattern.hasMatch(input)) {
        foundWords.add(word);
      }
    }

    return foundWords;
  }

  /// Add custom bad words to the filter
  /// Returns a new filter function with extended word list
  static String Function(String) withCustomWords(List<String> customWords) {
    final allWords = [..._badWords, ...customWords];

    return (String input) {
      if (input.isEmpty) return input;

      String result = input;

      for (final word in allWords) {
        final pattern = RegExp(
          r'\b' + RegExp.escape(word) + r'\b',
          caseSensitive: false,
          unicode: true,
        );

        result = result.replaceAllMapped(pattern, (match) {
          return _replacementChar * match.group(0)!.length;
        });
      }

      return result;
    };
  }
}
