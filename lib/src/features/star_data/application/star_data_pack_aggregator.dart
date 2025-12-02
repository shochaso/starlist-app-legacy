import 'package:intl/intl.dart';

import '../domain/star_data_item.dart';
import '../domain/star_data_pack.dart';
import '../utils/star_data_category_definitions.dart';

final _categoryPriority = ['shopping', 'youtube', 'video', 'music', 'receipt'];

List<StarDataPack> aggregateStarDataIntoPacks(
  List<StarDataItem> items, {
  String? starId,
}) {
  if (items.isEmpty) return [];

  final grouped = <String, List<StarDataItem>>{};
  for (final item in items) {
    final dateKey = _dayKeyFromDate(item.date);
    final groupKey = '${starId ?? item.starId}_$dateKey';
    grouped.putIfAbsent(groupKey, () => []).add(item);
  }

  final packs = grouped.entries.map((entry) {
    final dayStamps = entry.value;
    final counts = <String, int>{};
    for (final item in dayStamps) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final mainCategory = _determineMainCategory(counts);
    final mainSummaryText = _formatSummaryText(mainCategory, counts[mainCategory] ?? 0);
    final secondarySummary = _buildSecondarySummary(counts, mainCategory);
    final date = _parseDateKey(entry.key, dayStamps.first.starId);
    
    // Resolve enum values
    final resolvedCategory = StarDataCategory.fromString(mainCategory);
    // For genre, we pick the genre of the first item in the pack for now, 
    // assuming homogeneity or main item priority. 
    // In a more complex logic, we would count genres too.
    final firstItem = dayStamps.firstWhere(
      (item) => item.category == mainCategory, 
      orElse: () => dayStamps.first
    );
    final resolvedGenre = StarDataGenre.fromString(firstItem.genre);

    return StarDataPack(
      id: entry.key,
      starId: entry.value.first.starId,
      date: date,
      categoryCounts: counts,
      mainCategory: mainCategory,
      mainSummaryText: mainSummaryText,
      secondarySummaryText: secondarySummary,
      items: List.unmodifiable(entry.value),
      resolvedCategory: resolvedCategory,
      resolvedGenre: resolvedGenre,
    );
  }).toList();

  packs.sort((a, b) => b.date.compareTo(a.date));
  return packs;
}

String _dayKeyFromDate(DateTime date) {
  final converted = DateTime(date.year, date.month, date.day);
  return DateFormat('yyyyMMdd').format(converted);
}

DateTime _parseDateKey(String key, String starId) {
  final parts = key.split('_');
  final datePart = parts.length > 1 ? parts[1] : key;
  try {
    return DateFormat('yyyyMMdd').parse(datePart);
  } catch (_) {
    return DateTime.now();
  }
}

String _determineMainCategory(Map<String, int> counts) {
  if (counts.isEmpty) return 'other';
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final diff = b.value.compareTo(a.value);
      if (diff != 0) return diff;
      final priorityA = _categoryPriority.indexOf(a.key);
      final priorityB = _categoryPriority.indexOf(b.key);
      return priorityA.compareTo(priorityB);
    });
  return sorted.first.key;
}

String _formatSummaryText(String category, int count) {
  switch (category) {
    case 'shopping':
      return '$countつの商品を購入';
    case 'youtube':
      return '$count本の動画を視聴';
    case 'video':
      return '$count本の動画';
    case 'music':
      return '$count曲の音楽を再生';
    case 'receipt':
      return '$count件のレシート';
    default:
      return '$count件のデータ';
  }
}

String? _buildSecondarySummary(Map<String, int> counts, String mainCategory) {
  final others = counts.entries
      .where((entry) => entry.key != mainCategory)
      .fold<int>(0, (prev, entry) => prev + entry.value);
  if (others == 0) return null;
  return '他$others件のデータ';
}
