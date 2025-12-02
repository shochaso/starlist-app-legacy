import 'star_data_category_definitions.dart';

class StarDataServiceOption {
  const StarDataServiceOption({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final StarDataCategory category;
}

const String kServiceIdAll = 'all';

const StarDataServiceOption kServiceOptionAll = StarDataServiceOption(
  id: kServiceIdAll,
  label: 'すべて',
  category: StarDataCategory.other, // Dummy category for 'all' option
);

const List<StarDataServiceOption> kStarDataServiceOptions = [
  // Video (YouTube)
  StarDataServiceOption(
    id: 'youtube',
    label: 'YouTube',
    category: StarDataCategory.youtube,
  ),
  StarDataServiceOption(
    id: 'prime_video',
    label: 'Prime Video',
    category: StarDataCategory.video,
  ),
  StarDataServiceOption(
    id: 'abema',
    label: 'ABEMA',
    category: StarDataCategory.video,
  ),
  StarDataServiceOption(
    id: 'netflix',
    label: 'Netflix',
    category: StarDataCategory.video,
  ),
  StarDataServiceOption(
    id: 'tver',
    label: 'TVer',
    category: StarDataCategory.video,
  ),

  // Shopping
  StarDataServiceOption(
    id: 'amazon',
    label: 'Amazon',
    category: StarDataCategory.shopping,
  ),
  StarDataServiceOption(
    id: 'rakuten',
    label: '楽天市場',
    category: StarDataCategory.shopping,
  ),
  StarDataServiceOption(
    id: 'yahoo_shopping',
    label: 'Yahoo!ショッピング',
    category: StarDataCategory.shopping,
  ),
  StarDataServiceOption(
    id: 'convenience_store',
    label: 'コンビニ',
    category: StarDataCategory.shopping,
  ),
  StarDataServiceOption(
    id: 'mercari',
    label: 'メルカリ',
    category: StarDataCategory.shopping,
  ),

  // Music
  StarDataServiceOption(
    id: 'youtube_music',
    label: 'YouTube Music',
    category: StarDataCategory.music,
  ),
  StarDataServiceOption(
    id: 'spotify',
    label: 'Spotify',
    category: StarDataCategory.music,
  ),
  StarDataServiceOption(
    id: 'apple_music',
    label: 'Apple Music',
    category: StarDataCategory.music,
  ),
  StarDataServiceOption(
    id: 'amazon_music',
    label: 'Amazon Music',
    category: StarDataCategory.music,
  ),
  StarDataServiceOption(
    id: 'line_music',
    label: 'LINE MUSIC',
    category: StarDataCategory.music,
  ),

  // Receipt
  StarDataServiceOption(
    id: 'receipt_convenience',
    label: 'コンビニ',
    category: StarDataCategory.receipt,
  ),
  StarDataServiceOption(
    id: 'receipt_supermarket',
    label: 'スーパー',
    category: StarDataCategory.receipt,
  ),
  StarDataServiceOption(
    id: 'receipt_drugstore',
    label: 'ドラッグストア',
    category: StarDataCategory.receipt,
  ),
  StarDataServiceOption(
    id: 'receipt_restaurant',
    label: '外食チェーン',
    category: StarDataCategory.receipt,
  ),
  StarDataServiceOption(
    id: 'receipt_online',
    label: 'ネット通販',
    category: StarDataCategory.receipt,
  ),
];

List<StarDataServiceOption> getServicesForCategory(StarDataCategory category) {
  return [
    kServiceOptionAll,
    ...kStarDataServiceOptions.where((s) => s.category == category),
  ];
}
