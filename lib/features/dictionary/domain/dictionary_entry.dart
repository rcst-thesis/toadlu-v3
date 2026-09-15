/// A single dictionary word entry. [id] is the stable key used for
/// favoriting (persisted in `LearnerProfile.favoritedWords`), independent of
/// [word] so display text can change without breaking saved favorites.
class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.definition,
    required this.example,
    required this.imageAsset,
    required this.category,
    this.featured = false,
    this.frontCardImage,
    this.favThumbImage,
  });

  final String id;
  final String word;
  final String phonetic;
  final String definition;
  final String example;
  final String imageAsset;

  /// Groups entries for the browse screen's category filter/catalog
  /// sections (e.g. "home", "animals", "family").
  final String category;

  /// Whether this entry can appear in the browse screen's "featured" bento
  /// tray. Independent of having dedicated art -- the tray shows plain
  /// placeholder boxes regardless.
  final bool featured;

  /// A fully-designed front-card image (art + word label already baked in)
  /// for the word-of-the-day flip card specifically. When null, the flip
  /// card's front face falls back to the generic [imageAsset] + Flutter-
  /// drawn label composition that every entry uses for the favorites
  /// carousel/search thumbnails regardless.
  final String? frontCardImage;

  /// A fully-designed small card image (art + word label already baked in)
  /// for the favorites carousel and search-result thumbnails. When null,
  /// those fall back to the generic [imageAsset] + Flutter-drawn label
  /// composition.
  final String? favThumbImage;
}
