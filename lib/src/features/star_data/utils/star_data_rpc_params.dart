import 'star_id_resolver.dart';

Map<String, dynamic> buildItemsParams({
  required String username,
  required DateTime date,
  String? category,
  String? genre,
}) {
  final starId = StarIdResolver.usernameToStarId(username);
  return {
    'p_star_id': starId,
    'p_occurred_at': _formatDate(date),
    'p_category': category,
    'p_genre': genre,
  };
}

Map<String, dynamic> buildPackParams({required String packId}) {
  return {'p_pack_id': packId};
}

Map<String, dynamic> buildSummaryParams({required String username}) {
  return {
    'p_star_id': StarIdResolver.usernameToStarId(username),
  };
}

String _formatDate(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day).toUtc();
  return normalized.toIso8601String().split('T').first;
}
