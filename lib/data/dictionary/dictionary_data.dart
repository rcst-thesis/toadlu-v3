import 'package:tudloapp/data/dictionary/dictionary_item.dart';

export 'package:tudloapp/data/dictionary/dictionary_item.dart';

/// Word-based lookup data for Dictionary, Translation, and word tooltips.
///
/// This dataset is intentionally separate from LessonBank. LessonBank can hold
/// unit-based phrases, sentences, missing-word prompts, and image-card content;
/// this file should stay focused on dictionary-style word entries.
class DictionaryData {
  static const entries = [
    DictionaryEntry(hiligaynon: 'abyan', english: 'friend'),
    DictionaryEntry(hiligaynon: 'adlaw', english: 'day'),
    DictionaryEntry(hiligaynon: 'aga', english: 'morning'),
    DictionaryEntry(hiligaynon: 'ako', english: 'me / I'),
    DictionaryEntry(hiligaynon: 'balay', english: 'house'),
    DictionaryEntry(hiligaynon: 'bakal', english: 'buy'),
    DictionaryEntry(hiligaynon: 'basa', english: 'read'),
    DictionaryEntry(hiligaynon: 'bata', english: 'child'),
    DictionaryEntry(hiligaynon: 'bwas', english: 'tomorrow'),
    DictionaryEntry(hiligaynon: 'bulig', english: 'help'),
    DictionaryEntry(hiligaynon: 'buligan', english: 'help'),
    DictionaryEntry(hiligaynon: 'daku', english: 'big'),
    DictionaryEntry(hiligaynon: 'dalan', english: 'road'),
    DictionaryEntry(hiligaynon: 'diin', english: 'where'),
    DictionaryEntry(hiligaynon: 'eskwelahan', english: 'school'),
    DictionaryEntry(hiligaynon: 'gab-i', english: 'night / evening'),
    DictionaryEntry(hiligaynon: 'gamay', english: 'small'),
    DictionaryEntry(hiligaynon: 'gwapa', english: 'beautiful'),
    DictionaryEntry(hiligaynon: 'gwapo', english: 'handsome'),
    DictionaryEntry(hiligaynon: 'hambal', english: 'speak'),
    DictionaryEntry(hiligaynon: 'hapon', english: 'afternoon'),
    DictionaryEntry(hiligaynon: 'hatag', english: 'give'),
    DictionaryEntry(hiligaynon: 'hinay', english: 'slow'),
    DictionaryEntry(hiligaynon: 'huo', english: 'yes'),
    DictionaryEntry(hiligaynon: 'ikaw', english: 'you'),
    DictionaryEntry(hiligaynon: 'indi', english: 'no'),
    DictionaryEntry(hiligaynon: 'inom', english: 'drink'),
    DictionaryEntry(hiligaynon: 'ido', english: 'dog'),
    DictionaryEntry(hiligaynon: 'kuring', english: 'cat'),
    DictionaryEntry(hiligaynon: 'kaon', english: 'eat'),
    DictionaryEntry(hiligaynon: 'kan-on', english: 'rice'),
    DictionaryEntry(hiligaynon: 'kami', english: 'we'),
    DictionaryEntry(hiligaynon: 'kapoy', english: 'tired'),
    DictionaryEntry(hiligaynon: 'lakat', english: 'walk'),
    DictionaryEntry(hiligaynon: 'libro', english: 'book'),
    DictionaryEntry(hiligaynon: 'maayong', english: 'good'),
    DictionaryEntry(hiligaynon: 'maestra', english: 'teacher'),
    DictionaryEntry(hiligaynon: 'maestro', english: 'teacher'),
    DictionaryEntry(hiligaynon: 'mainit', english: 'hot'),
    DictionaryEntry(hiligaynon: 'mangga', english: 'mango'),
    DictionaryEntry(hiligaynon: 'mapait', english: 'bitter'),
    DictionaryEntry(hiligaynon: 'masadya', english: 'happy'),
    DictionaryEntry(hiligaynon: 'matam-is', english: 'sweet'),
    DictionaryEntry(hiligaynon: 'matugnaw', english: 'cold'),
    DictionaryEntry(hiligaynon: 'merkado', english: 'market'),
    DictionaryEntry(hiligaynon: 'mo', english: 'you / your'),
    DictionaryEntry(hiligaynon: 'nanay', english: 'mother'),
    DictionaryEntry(hiligaynon: 'ngaa', english: 'why'),
    DictionaryEntry(hiligaynon: 'ngalan', english: 'name'),
    DictionaryEntry(hiligaynon: 'pagkaon', english: 'food'),
    DictionaryEntry(hiligaynon: 'palihog', english: 'please'),
    DictionaryEntry(hiligaynon: 'pamati', english: 'listen'),
    DictionaryEntry(hiligaynon: 'pila', english: 'how much'),
    DictionaryEntry(hiligaynon: 'plete', english: 'fare'),
    DictionaryEntry(hiligaynon: 'puno', english: 'tree'),
    DictionaryEntry(hiligaynon: 'pwede', english: 'can / may'),
    DictionaryEntry(hiligaynon: 'salamat', english: 'thank you'),
    DictionaryEntry(hiligaynon: 'sang', english: 'of'),
    DictionaryEntry(hiligaynon: 'san-o', english: 'when'),
    DictionaryEntry(hiligaynon: 'sila', english: 'they'),
    DictionaryEntry(hiligaynon: 'subong', english: 'now'),
    DictionaryEntry(hiligaynon: 'sulat', english: 'write'),
    DictionaryEntry(hiligaynon: 'tagpila', english: 'how much'),
    DictionaryEntry(hiligaynon: 'tatay', english: 'father'),
    DictionaryEntry(hiligaynon: 'terminal', english: 'terminal'),
    DictionaryEntry(hiligaynon: 'tindahan', english: 'store'),
    DictionaryEntry(hiligaynon: 'tubig', english: 'water'),
    DictionaryEntry(hiligaynon: 'tuon', english: 'study'),
  ];

  /// Small phrase support for the Translation page. Full lesson sentences
  /// should remain in LessonBank instead of becoming dictionary entries.
  ///
  /// TRANSLATION DATA
  static const phraseTranslations = {
    'maayong aga': 'good morning',
    'maayong hapon': 'good afternoon',
    'maayong gab-i': 'good evening',
    'good morning': 'maayong aga',
    'good afternoon': 'maayong hapon',
    'good evening': 'maayong gab-i',
    'thank you': 'salamat',
    'pwede mo ako buligan': 'can you help me',
    'can you help me': 'pwede mo ako buligan',
  };

  static final Map<String, String> hiligaynonToEnglish = {
    for (final entry in entries) _normalize(entry.hiligaynon): entry.english,
  };

  static final Map<String, String> englishToHiligaynon = {
    for (final entry in entries)
      for (final meaning in _englishMeanings(entry.english))
        _normalize(meaning): entry.hiligaynon,
  };

  static String meaningFor(String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) return '';
    return hiligaynonToEnglish[normalized] ??
        englishToHiligaynon[normalized] ??
        phraseTranslations[normalized] ??
        '';
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(
      RegExp(r'^[^\w]+|[^\w]+$'),
      '',
    );
  }

  static List<String> _englishMeanings(String value) {
    return value
        .split(RegExp(r'\s*/\s*'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }
}
