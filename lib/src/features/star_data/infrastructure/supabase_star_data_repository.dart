import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/star_data_item.dart';
import '../domain/star_data_repository.dart';

class SupabaseStarDataRepository implements StarDataRepository {
  SupabaseStarDataRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) {
    return fetchStarData(starId: starId, limit: limit);
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async {
    try {
      final response = await client
          .from('star_data_items')
          .select()
          .eq('star_id', starId)
          .eq('is_hidden', false)
          .order('occurred_at', ascending: false)
          .limit(limit);

      if (response == null) {
        return [];
      }

      final data = response as List<dynamic>;
      return data.map((json) => _mapFromSupabase(json as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      print('[SupabaseStarDataRepository] Error fetching star_data_items for $starId: ${e.message}');
      return [];
    } catch (e) {
      print('[SupabaseStarDataRepository] Unexpected error fetching star_data_items for $starId: $e');
      return [];
    }
  }

  StarDataItem _mapFromSupabase(Map<String, dynamic> json) {
    // Map Supabase row to StarDataItem
    // Note: occurred_at is DATE in DB, but StarDataItem.date is DateTime
    final occurredAtStr = json['occurred_at'] as String?;
    final occurredAt = occurredAtStr != null
        ? DateTime.tryParse(occurredAtStr) ?? DateTime.now()
        : DateTime.now();

    final createdAtStr = json['created_at'] as String?;
    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();

    final rawPayload = json['raw_payload'] as Map<String, dynamic>?;
    final isHidden = json['is_hidden'] as bool? ?? false;
    return StarDataItem(
      id: json['id'] as String? ?? '',
      starId: json['star_id'] as String? ?? '',
      date: occurredAt,
      category: json['category'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      source: json['source'] as String? ?? '',
      createdAt: createdAt,
      isHidden: isHidden,
      extra: rawPayload,
    );
  }

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {
    try {
      await client.from('star_data_items').update({
        'is_hidden': true,
        'hidden_at': DateTime.now().toUtc().toIso8601String(),
      }).match({
        'id': id,
        'star_id': starId,
      });
    } on PostgrestException catch (e) {
      print('[SupabaseStarDataRepository] Error hiding star_data_item $id: ${e.message}');
    } catch (e) {
      print('[SupabaseStarDataRepository] Unexpected error hiding star_data_item $id: $e');
    }
  }

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {
    try {
      // Contract: id/star_id/category/title/occurred_at must be provided according to star_data_items schema.
      await client.from('star_data_items').insert({
        'id': item.id,
        'star_id': item.starId,
        'category': item.category,
        'genre': item.genre,
        'title': item.title,
        'subtitle': item.subtitle,
        'source': item.source,
        'occurred_at': item.date.toIso8601String(),
        'created_at': item.createdAt.toIso8601String(),
        'raw_payload': item.extra,
      });
    } on PostgrestException catch (e) {
      print('[SupabaseStarDataRepository] Error saving star_data_item for ${item.starId}: ${e.message}');
    } catch (e) {
      print('[SupabaseStarDataRepository] Unexpected error saving star_data_item for ${item.starId}: $e');
    }
  }
}
