import 'package:flutter_test/flutter_test.dart';
import 'package:starlist_app/data/models/genre_taxonomy.dart';
import 'package:starlist_app/features/star_data/domain/category.dart';
import 'package:starlist_app/features/star_data/domain/star_data_genre_resolver.dart';

void main() {
  group('resolveGenreLabels', () {
    test('returns matching labels for known slugs', () {
      final labels = resolveGenreLabels(
        taxonomy: DefaultGenreTaxonomy.data,
        category: StarDataCategory.youtube,
        genreSlugs: ['variety', 'anime'],
      );

      expect(labels, contains('バラエティ'));
      expect(labels, contains('アニメ'));
    });

    test('ignores unknown slugs and returns empty list if none match', () {
      final labels = resolveGenreLabels(
        taxonomy: DefaultGenreTaxonomy.data,
        category: StarDataCategory.music,
        genreSlugs: ['unknown_slug'],
      );

      expect(labels, isEmpty);
    });
  });
}



