import 'package:starlist_app/data/models/genre_taxonomy.dart';

import 'category.dart';

const Map<StarDataCategory, String> _categoryTaxonomyKey = {
  StarDataCategory.youtube: 'video',
  StarDataCategory.shopping: 'shopping',
  StarDataCategory.music: 'music',
  StarDataCategory.food: 'food_delivery',
  StarDataCategory.anime: 'video',
  StarDataCategory.other: 'shopping',
};

List<String> resolveGenreLabels({
  required GenreTaxonomyV1 taxonomy,
  required StarDataCategory category,
  required List<String> genreSlugs,
}) {
  if (genreSlugs.isEmpty) return [];

  final key = _categoryTaxonomyKey[category] ?? 'video';
  final categoryData = taxonomy.getCategory(key);
  if (categoryData == null) return [];

  final labels = <String>{};
  for (final slug in genreSlugs) {
    for (final genre in categoryData.genres) {
      if (genre.slug == slug) {
        labels.add(genre.label);
        break;
      }
    }
  }

  return labels.toList();
}




