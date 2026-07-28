class ChildSafetyFilter {
  static const blockedMessage = "Let's use child-friendly words.";

  static const _blockedWords = {
    'asshole',
    'bitch',
    'buang',
    'fack',
    'fuck',
    'linti',
    'nude',
    'oten',
    'pisti',
    'porn',
    'shit',
    'suicide',
    'yawa',
  };

  static const _allowedWords = {'i'};

  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    _ready = true;
  }

  static bool isUnsafe(String text) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) return false;

    return RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(normalized)
        .map((match) => match.group(0)!)
        .where((word) => !_allowedWords.contains(word))
        .any(_blockedWords.contains);
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('@', 'a')
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('7', 't');
  }
}
