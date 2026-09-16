import 'package:flutter_test/flutter_test.dart';

import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';
import 'package:tudlo/features/dictionary/domain/dictionary_search.dart';

const _pool = [
  DictionaryEntry(
    id: 'balay',
    word: 'balay',
    phonetic: '/ba-lay/',
    definition: 'n. house.',
    example: 'test',
    category: 'home',
  ),
  DictionaryEntry(
    id: 'adobo',
    word: 'adóbo',
    phonetic: '/a-do-bo/',
    definition: 'n. meat cooked in vinegar.',
    example: 'test',
    category: 'food',
  ),
  DictionaryEntry(
    id: 'kan-on',
    word: 'kan-on',
    phonetic: '/kan-on/',
    definition: 'n. rice.',
    example: 'test',
    category: 'food',
  ),
];

void main() {
  group('normalizeForSearch', () {
    test('strips accents', () {
      expect(normalizeForSearch('adóbo'), 'adobo');
      // 'i' folds to 'e' (see phonetic folding below), so "gáb-i" ->
      // "gabe", not "gabi".
      expect(normalizeForSearch('gáb-i'), 'gabe');
    });

    test('drops hyphens, apostrophes, spaces, and curly quotes', () {
      // 'k' folds to 'c' (phonetic folding), so "kan-on" -> "canon".
      expect(normalizeForSearch('kan-on'), 'canon');
      // 'i' folds to 'e'.
      expect(normalizeForSearch('ara dira'), 'aradera');
      expect(normalizeForSearch('“diin”'), 'deen');
    });

    test('lowercases', () {
      // 'i' folds to 'e'.
      expect(normalizeForSearch('Abril'), 'abrel');
    });

    test('folds phonetically-interchangeable letters together', () {
      expect(normalizeForSearch('kuring'), normalizeForSearch('koring'));
      expect(normalizeForSearch('lalaki'), normalizeForSearch('lalake'));
      expect(normalizeForSearch('baka'), normalizeForSearch('vaka'));
      expect(normalizeForSearch('kolor'), normalizeForSearch('color'));
    });
  });

  group('matchesSearch', () {
    test('empty query always matches', () {
      expect(matchesSearch('anything', ''), isTrue);
    });

    test('matches accented words against a plain-ASCII query', () {
      expect(matchesSearch('adóbo', 'adobo'), isTrue);
      expect(matchesSearch('adóbo', 'ado'), isTrue);
    });

    test('matches hyphenated words against a query with no hyphen', () {
      expect(matchesSearch('kan-on', 'kanon'), isTrue);
      expect(matchesSearch('bís-ak', 'bisak'), isTrue);
    });

    test('matches multi-word entries against a query with no space', () {
      expect(matchesSearch('ara dira', 'aradira'), isTrue);
    });

    test('is case-insensitive', () {
      expect(matchesSearch('Abril', 'abril'), isTrue);
      expect(matchesSearch('abril', 'ABRIL'), isTrue);
    });

    test('still rejects a genuinely non-matching query', () {
      expect(matchesSearch('adóbo', 'xyz'), isFalse);
    });

    test('matches across phonetically-interchangeable letters', () {
      expect(matchesSearch('kuring', 'koring'), isTrue);
      expect(matchesSearch('baka', 'vaka'), isTrue);
      expect(matchesSearch('kolor', 'color'), isTrue);
    });
  });

  group('closestWordMatches', () {
    test('suggests the right word for a single typo\'d letter', () {
      final matches = closestWordMatches('balay', _pool);
      // Exact match has distance 0 and is excluded -- this isn't the "did
      // you mean" path when the query already matches exactly.
      expect(matches, isEmpty);

      final typoMatches = closestWordMatches('balat', _pool);
      expect(typoMatches.map((e) => e.id), contains('balay'));
    });

    test('typo tolerance scales with query length', () {
      // "adobo" (5 letters) vs "adóbo" normalized to "adobo" is an exact
      // match (distance 0), so try a couple of real typos instead.
      expect(
        closestWordMatches('adoba', _pool).map((e) => e.id),
        contains('adobo'),
      );
      expect(
        closestWordMatches('adova', _pool).map((e) => e.id),
        contains('adobo'),
      );
    });

    test('accents/hyphens do not count as typos', () {
      // "kanon" (no hyphen) should match "kan-on" via normalization, not
      // edit distance -- but closestWordMatches only fires on an actual
      // typo gap, so a query that already normalizes-matches returns no
      // suggestions (matchesSearch already found it).
      expect(closestWordMatches('kanon', _pool), isEmpty);
    });

    test('returns nothing for a wildly different query', () {
      expect(closestWordMatches('zzzzzzzzzz', _pool), isEmpty);
    });

    test('empty query returns nothing', () {
      expect(closestWordMatches('', _pool), isEmpty);
    });
  });
}
