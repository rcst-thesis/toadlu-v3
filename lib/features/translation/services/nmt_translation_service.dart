import 'package:tudloapp/data/dictionary/dictionary_data.dart';

class NmtTranslationService {
  bool _closed = false;

  Future<String> translate(String text) async {
    if (_closed) throw StateError('Translation service is closed.');

    final input = text.trim();
    if (input.isEmpty) return '';

    await DictionaryData.initialize();
    final directMatch = DictionaryData.meaningFor(input).trim();
    if (directMatch.isNotEmpty) return directMatch;

    final translatedWords = input.split(RegExp(r'(\s+)')).map((part) {
      if (part.trim().isEmpty) return part;
      final punctuation = RegExp(
        r'(^[^\p{L}\p{N}]*)(.*?)([^\p{L}\p{N}]*$)',
        unicode: true,
      ).firstMatch(part);
      if (punctuation == null) return part;
      final prefix = punctuation.group(1) ?? '';
      final word = punctuation.group(2) ?? '';
      final suffix = punctuation.group(3) ?? '';
      final match = DictionaryData.meaningFor(word).trim();
      return match.isEmpty ? part : '$prefix$match$suffix';
    }).join();

    return translatedWords == input ? '' : translatedWords;
  }

  Future<void> close() async {
    _closed = true;
  }
}
