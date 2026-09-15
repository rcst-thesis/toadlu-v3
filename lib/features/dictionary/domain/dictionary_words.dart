import 'package:tudlo/features/dictionary/domain/dictionary_entry.dart';

/// Placeholder dictionary content: not real curriculum data. Each entry's
/// [DictionaryEntry.imageAsset] is a thematic stand-in reused from existing
/// sticker art (no dedicated dictionary illustrations exist yet, aside from
/// `balay`'s) -- swap these for real art/content when it's available.
abstract final class DictionaryWords {
  static const all = <DictionaryEntry>[
    DictionaryEntry(
      id: 'balay',
      word: 'balay',
      phonetic: '/ba-lay/',
      definition:
          'n. ang balay ay isa ka pisikal nga tinukod ukon estraktura nga '
          'gindesinyo kag gintukod para istaran sang mga tawo.',
      example: 'naga istar ako sa akon balay',
      imageAsset: 'assets/images/home_sticker_house.png',
      category: 'home',
      featured: true,
      frontCardImage: 'assets/images/balay_dictionary.png',
      favThumbImage: 'assets/images/balay_dictionary_fav_thumb.png',
    ),
    DictionaryEntry(
      id: 'ido',
      word: 'ido',
      phonetic: '/i-do/',
      definition: 'n. ang ido isa ka sapat nga sagad ginabantayan sang tawo.',
      example: 'nagahulat ang akon ido sa balay',
      imageAsset: 'assets/images/home_sticker_dog.png',
      category: 'animals',
      featured: true,
    ),
    DictionaryEntry(
      id: 'kuring',
      word: 'kuring',
      phonetic: '/ku-ring/',
      definition: 'n. ang kuring isa ka gamay nga sapat nga sagad ginaatipan '
          'sa balay.',
      example: 'nagatulog ang kuring sa ibabaw sang lamesa',
      imageAsset: 'assets/images/home_sticker_cat.png',
      category: 'animals',
      featured: true,
    ),
    DictionaryEntry(
      id: 'iloy',
      word: 'iloy',
      phonetic: '/i-loy/',
      definition: 'n. ang iloy amo ang babaye nga ginikanan.',
      example: 'nagabasa sang libro ang akon iloy para sa akon',
      imageAsset: 'assets/images/home_sticker_mother.png',
      category: 'family',
      featured: true,
    ),
    DictionaryEntry(
      id: 'amay',
      word: 'amay',
      phonetic: '/a-may/',
      definition: 'n. ang amay amo ang lalaki nga ginikanan.',
      example: 'nagatudlo ang akon amay sa akon magbisikleta',
      imageAsset: 'assets/images/home_sticker_mother.png',
      category: 'family',
    ),
    DictionaryEntry(
      id: 'tubig',
      word: 'tubig',
      phonetic: '/tu-big/',
      definition: 'n. ang tubig isa ka likido nga kinahanglanon sa kabuhi.',
      example: 'nagainom ako sang tubig kada adlaw',
      imageAsset: 'assets/images/home_sticker_beach.png',
      category: 'nature',
      featured: true,
    ),
    DictionaryEntry(
      id: 'uma',
      word: 'uma',
      phonetic: '/u-ma/',
      definition: 'n. ang uma isa ka lugar nga ginatamnan sang mga pananom.',
      example: 'nagatrabaho ang akon lolo sa uma',
      imageAsset: 'assets/images/home_sticker_farm.png',
      category: 'nature',
      featured: true,
    ),
    DictionaryEntry(
      id: 'kan-on',
      word: 'kan-on',
      phonetic: '/kan-on/',
      definition: 'n. ang kan-on isa ka pagkaon nga halin sa bugas.',
      example: 'nagakaon kami sang kan-on sa paniudto',
      imageAsset: 'assets/images/home_sticker_market.png',
      category: 'food',
      featured: true,
    ),
    DictionaryEntry(
      id: 'tinapay',
      word: 'tinapay',
      phonetic: '/ti-na-pay/',
      definition: 'n. ang tinapay isa ka pagkaon nga ginluto halin sa arina.',
      example: 'nagapamalit kami sang tinapay sa tinda',
      imageAsset: 'assets/images/home_sticker_market.png',
      category: 'food',
    ),
    DictionaryEntry(
      id: 'simbahan',
      word: 'simbahan',
      phonetic: '/sim-ba-han/',
      definition: 'n. ang simbahan isa ka lugar nga ginasimbahan sang mga '
          'tawo.',
      example: 'nagasimba kami sa simbahan kada Domingo',
      imageAsset: 'assets/images/home_sticker_church.png',
      category: 'places',
      featured: true,
    ),
    DictionaryEntry(
      id: 'parke',
      word: 'parke',
      phonetic: '/par-ke/',
      definition: 'n. ang parke isa ka lugar nga ginadulaan sang mga bata.',
      example: 'nagadula kami sa parke pagkatapos sang klase',
      imageAsset: 'assets/images/home_sticker_park.png',
      category: 'places',
    ),
    DictionaryEntry(
      id: 'eskwelahan',
      word: 'eskwelahan',
      phonetic: '/es-kwe-la-han/',
      definition: 'n. ang eskwelahan isa ka lugar nga ginatun-an sang mga '
          'bata.',
      example: 'nagatambong ako sa eskwelahan kada adlaw',
      imageAsset: 'assets/images/home_sticker_school.png',
      category: 'places',
      featured: true,
    ),
  ];
}
