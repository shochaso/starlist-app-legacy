import 'package:test/test.dart';

import 'package:starlist_app/src/features/star_data/utils/star_data_rpc_params.dart';

void main() {
  group('star data rpc params', () {
    test('builds items params honoring category/genre and formatting date', () {
      final params = buildItemsParams(
        username: 'hanayama-mizuki',
        date: DateTime(2025, 3, 5),
        category: 'youtube',
        genre: 'video_variety',
      );

      expect(
        params,
        equals({
          'p_star_id': 'star_hanayama_mizuki',
          'p_occurred_at': _formatDateForTest(DateTime(2025, 3, 5)),
          'p_category': 'youtube',
          'p_genre': 'video_variety',
        }),
      );
    });

    test('builds pack params straight through', () {
      expect(
        buildPackParams(packId: 'hanayama-mizuki::2025-10-07'),
        equals({'p_pack_id': 'hanayama-mizuki::2025-10-07'}),
      );
    });

    test('builds summary params using resolved star id', () {
      expect(
        buildSummaryParams(username: 'kato-junichi'),
        equals({'p_star_id': 'star_kato_junichi'}),
      );
    });
  });
}

String _formatDateForTest(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day).toUtc();
  return normalized.toIso8601String().split('T').first;
}
