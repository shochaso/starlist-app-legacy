import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:starlist_app/src/core/config/supabase_client_provider.dart';

import '../../data/star_data_repository.dart';
import '../../data/supabase_star_data_repository.dart';
import '../../models/star_data_item.dart';
import '../../models/star_data_pack.dart';

/// Controls whether the new data page should render mock assets.
final starDataMockModeProvider = Provider<bool>((_) {
  const useMock =
      bool.fromEnvironment('STAR_DATA_USE_MOCK', defaultValue: true);
  return useMock;
});

/// Repository instance dedicated to the `/stars/:username/data` experience.
final starDataPageRepositoryProvider = Provider<StarDataRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final useMock = ref.watch(starDataMockModeProvider);
  return SupabaseStarDataRepository(
    client: supabase,
    mock: useMock,
  );
});

/// Tracks which date is currently selected in the data page filters.
final selectedDateProvider = StateProvider<DateTime>(
  (_) => _todayAtMidnight(),
);

/// Holds category and genre filters used by the data page.
final starDataFilterProvider = StateProvider<StarDataFilter>(
  (_) => const StarDataFilter(),
);

/// Loads StarDataItems for a username/date/filters combination.
final starDataItemsProvider =
    FutureProvider.family<List<StarDataItem>, StarDataItemsQuery>(
  (ref, query) async {
    final repository = ref.watch(starDataPageRepositoryProvider);
    return repository.fetchItems(
      username: query.username,
      date: query.date,
      category: query.category,
      genre: query.genre,
    );
  },
);

/// Retrieves a specific pack (e.g. daily bundle) by its identifier.
final starDataPackProvider =
    FutureProvider.family<StarDataPack, String>((ref, packId) async {
  final repository = ref.watch(starDataPageRepositoryProvider);
  return repository.fetchPack(packId);
});

/// Determines whether a paywall should appear for a given category.
final planRequirementProvider =
    Provider<PlanRequirement>((_) => const PlanRequirement());

@immutable
class StarDataFilter {
  const StarDataFilter({
    this.category,
    this.genre,
  });

  final String? category;
  final String? genre;

  StarDataFilter copyWith({
    String? category,
    String? genre,
  }) {
    return StarDataFilter(
      category: category ?? this.category,
      genre: genre ?? this.genre,
    );
  }
}

@immutable
class StarDataItemsQuery {
  const StarDataItemsQuery({
    required this.username,
    required this.date,
    this.category,
    this.genre,
  });

  final String username;
  final DateTime date;
  final String? category;
  final String? genre;

  StarDataItemsQuery copyWith({
    String? username,
    DateTime? date,
    String? category,
    String? genre,
  }) {
    return StarDataItemsQuery(
      username: username ?? this.username,
      date: date ?? this.date,
      category: category ?? this.category,
      genre: genre ?? this.genre,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StarDataItemsQuery &&
        other.username == username &&
        other.date == date &&
        other.category == category &&
        other.genre == genre;
  }

  @override
  int get hashCode =>
      username.hashCode ^
      date.hashCode ^
      (category?.hashCode ?? 0) ^
      (genre?.hashCode ?? 0);
}

@immutable
class PlanRequirement {
  const PlanRequirement();

  static const _freeCategories = {'youtube'};

  bool requiresPlanForCategory(String category) {
    return !_freeCategories.contains(category.toLowerCase());
  }

  bool isFreeCategory(String category) => !requiresPlanForCategory(category);
}

DateTime _todayAtMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
