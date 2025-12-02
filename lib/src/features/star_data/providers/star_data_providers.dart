import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starlist_app/src/core/config/supabase_client_provider.dart';
import 'package:starlist_app/config/environment_config.dart';

import '../domain/star_data_daily_query.dart';
import '../domain/star_data_item.dart';
import '../domain/star_data_pack.dart';
import '../domain/star_data_repository.dart';
import '../infrastructure/mock_star_data_repository.dart';
import '../infrastructure/supabase_star_data_repository.dart';
import '../application/star_data_pack_aggregator.dart';
import '../utils/star_data_pack_timeline.dart';

/// Flag to switch between Mock and Supabase repository.
/// Set USE_SUPABASE_STAR_DATA=true to use Supabase, otherwise Mock is used.
final useSupabaseStarDataProvider = Provider<bool>((ref) {
  const useSupabase = bool.fromEnvironment(
    'USE_SUPABASE_STAR_DATA',
    defaultValue: false,
  );
  return useSupabase;
});

/// Repository provider that can switch between Mock and Supabase implementations.
/// Set USE_SUPABASE_STAR_DATA=true via --dart-define to use Supabase.
final starDataRepositoryProvider = Provider<StarDataRepository>((ref) {
  final useSupabase = ref.watch(useSupabaseStarDataProvider);

  if (useSupabase) {
    try {
      final client = ref.watch(supabaseClientProvider);
      return SupabaseStarDataRepository(client);
    } catch (e) {
      // Fallback to Mock if Supabase client is not available
      print('[starDataRepositoryProvider] Supabase unavailable, using Mock: $e');
      return MockStarDataRepository();
    }
  }

  // Default to Mock for development
  return MockStarDataRepository();
});

final starDataItemsProvider =
    FutureProvider.family<List<StarDataItem>, String>((ref, starId) async {
  final repository = ref.watch(starDataRepositoryProvider);
  return repository.getStarData(starId: starId);
});

final starDataItemsByDayProvider =
    FutureProvider.family<List<StarDataItem>, StarDataDailyQuery>(
  (ref, query) async {
    final items = await ref.watch(starDataItemsProvider(query.starId).future);
    final targetDay = DateTime(
      query.dateOnly.year,
      query.dateOnly.month,
      query.dateOnly.day,
    );
    return items.where((item) {
      final itemDay = DateTime(item.date.year, item.date.month, item.date.day);
      if (itemDay != targetDay) {
        return false;
      }
      if (query.category != null && item.category != query.category) {
        return false;
      }
      return true;
    }).toList();
  },
);

// Repository.fetchStarData already filters out hidden records (`is_hidden = false`),
// so packs only aggregate visible items.
final starDataPacksProvider =
    FutureProvider.family<List<StarDataPack>, String>((ref, starId) async {
  final items = await ref.watch(starDataItemsProvider(starId).future);
  if (items.isEmpty) return [];
  return aggregateStarDataIntoPacks(items, starId: starId);
});

final todayStarDataPackProvider =
    Provider.family<AsyncValue<StarDataPack?>, String>((ref, starId) {
  final asyncPacks = ref.watch(starDataPacksProvider(starId));
  return asyncPacks.whenData(findTodayStarDataPack);
});

final pastStarDataPacksProvider =
    Provider.family<AsyncValue<List<StarDataPack>>, String>((ref, starId) {
  final asyncPacks = ref.watch(starDataPacksProvider(starId));
  return asyncPacks.whenData((packs) => findPastStarDataPacks(packs));
});
