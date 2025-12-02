import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/star_data_item.dart';
import '../models/star_data_pack.dart';
import '../models/star_data_summary.dart';
import '../utils/star_data_rpc_params.dart';
import '../utils/star_id_resolver.dart';
import 'star_data_errors.dart';
import 'star_data_repository.dart';

class SupabaseStarDataRepository implements StarDataRepository {
  SupabaseStarDataRepository({
    required this.client,
    this.assetBundle,
    this.mock = false,
  });

  final SupabaseClient client;
  final AssetBundle? assetBundle;
  final bool mock;

  static const _mockItemsPath = 'assets/mocks/star_data/mock_items.json';
  static const _mockPackPath = 'assets/mocks/star_data/mock_pack.json';
  static const _mockSummaryPath = 'assets/mocks/star_data/mock_summary.json';

  List<StarDataItem>? _mockItems;

  AssetBundle get _bundle => assetBundle ?? rootBundle;

  @override
  Future<List<StarDataItem>> fetchItems({
    required String username,
    required DateTime date,
    String? category,
    String? genre,
  }) async {
    if (mock) {
      return _filterMockItems(
          username: username, date: date, category: category, genre: genre);
    }
    final params = buildItemsParams(
      username: username,
      date: date,
      category: category,
      genre: genre,
    );
    try {
      final response = await client.rpc('get_star_data_items', params: params);
      return _parseItemsResponse(response);
    } catch (error) {
      throw StarDataError.fetchItems(error.toString());
    }
  }

  @override
  Future<StarDataPack> fetchPack(String packId) async {
    if (mock) {
      return _loadMockPack(packId);
    }
    try {
      final response = await client.rpc('get_star_data_pack',
          params: buildPackParams(packId: packId));
      final parsed = _extractSingleRow(response);
      if (parsed == null) {
        throw StarDataError.fetchPack('no pack data returned for $packId');
      }
      return StarDataPack.fromJson(parsed);
    } catch (error) {
      throw StarDataError.fetchPack(error.toString());
    }
  }

  @override
  Future<void> hideItem(String itemId) async {
    if (mock) {
      return;
    }
    try {
      await client.from('star_data_items').update({
        'is_hidden': true,
        'hidden_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', itemId);
    } catch (error) {
      throw StarDataError.hideItem(error.toString());
    }
  }

  @override
  Future<StarDataSummary> fetchSummary(String username) async {
    if (mock) {
      return _loadMockSummary();
    }
    try {
      final response = await client.rpc('get_star_data_summary',
          params: buildSummaryParams(username: username));
      final parsed = _extractSingleRow(response);
      if (parsed == null) {
        throw StarDataError.fetchSummary('summary is empty for $username');
      }
      return StarDataSummary.fromJson(parsed);
    } catch (error) {
      throw StarDataError.fetchSummary(error.toString());
    }
  }

  Future<List<StarDataItem>> _filterMockItems({
    required String username,
    required DateTime date,
    String? category,
    String? genre,
  }) async {
    final items = await _loadMockItems();
    final targetDate = DateTime(date.year, date.month, date.day);
    final normalizedUsername = StarIdResolver.usernameToStarId(username);
    return items.where((item) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      if (itemDate != targetDate) {
        return false;
      }
      final matchesUser =
          item.username == username || item.username == normalizedUsername;
      if (!matchesUser) {
        return false;
      }
      if (category != null && item.category.value != category) {
        return false;
      }
      if (genre != null && item.genre?.value != genre) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<List<StarDataItem>> _loadMockItems() async {
    if (_mockItems != null) {
      return _mockItems!;
    }
    try {
      final raw = await _bundle.loadString(_mockItemsPath);
      final decoded = jsonDecode(raw) as List<dynamic>;
      final parsed = decoded
          .whereType<Map<String, dynamic>>()
          .map((entry) => StarDataItem.fromJson(entry))
          .toList();
      _mockItems = parsed;
      return parsed;
    } catch (error) {
      throw StarDataError.mockData('failed to load mock items: $error');
    }
  }

  Future<StarDataPack> _loadMockPack(String packId) async {
    try {
      final raw = await _bundle.loadString(_mockPackPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final normalizedId =
          (decoded['packId'] ?? decoded['pack_id']) as String? ?? '';
      if (normalizedId != packId) {
        throw StarDataError.fetchPack(
            'mock pack id mismatch ($packId vs $normalizedId)');
      }
      return StarDataPack.fromJson(decoded);
    } catch (error) {
      if (error is StarDataError) {
        rethrow;
      }
      throw StarDataError.fetchPack('failed to load mock pack: $error');
    }
  }

  Future<StarDataSummary> _loadMockSummary() async {
    try {
      final raw = await _bundle.loadString(_mockSummaryPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return StarDataSummary.fromJson(decoded);
    } catch (error) {
      throw StarDataError.fetchSummary('failed to load mock summary: $error');
    }
  }

  List<StarDataItem> _parseItemsResponse(dynamic response) {
    if (response == null) {
      return [];
    }
    final rows = response as List<dynamic>? ?? [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(StarDataItem.fromJson)
        .toList();
  }

  Map<String, dynamic>? _extractSingleRow(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is List<dynamic>) {
      if (response.isEmpty) {
        return null;
      }
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
    }
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }
}
