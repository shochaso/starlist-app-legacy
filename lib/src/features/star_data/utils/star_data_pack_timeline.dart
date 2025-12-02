import 'package:intl/intl.dart';

import '../domain/star_data_pack.dart';
import '../utils/star_data_category_definitions.dart';

const int kMaxPastStarDataDays = 30;

DateTime _truncateToDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDay(DateTime a, DateTime b) {
  final aDay = _truncateToDay(a);
  final bDay = _truncateToDay(b);
  return aDay.year == bDay.year &&
      aDay.month == bDay.month &&
      aDay.day == bDay.day;
}

StarDataPack? findTodayStarDataPack(List<StarDataPack> packs) {
  final today = _truncateToDay(DateTime.now());
  for (final pack in packs) {
    if (_isSameDay(pack.date, today)) {
      return pack;
    }
  }
  return null;
}

List<StarDataPack> findPastStarDataPacks(
  List<StarDataPack> packs, {
  int maxDays = kMaxPastStarDataDays,
}) {
  final today = _truncateToDay(DateTime.now());
  final filtered = packs
      .where((pack) => !_isSameDay(pack.date, today))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  if (maxDays >= filtered.length) {
    return filtered;
  }
  return filtered.sublist(0, maxDays);
}

List<StarDataPack> filterStarDataPacksByCategory(
    List<StarDataPack> packs, StarDataCategory? category) {
  if (category == null) {
    return packs;
  }
  return packs
      .where((pack) => pack.resolvedCategory == category)
      .toList();
}

List<StarDataPack> searchStarDataPacks(List<StarDataPack> packs, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) {
    return packs;
  }
  return packs
      .where((pack) =>
          _packMatchesQuery(pack, keyword))
      .toList();
}

bool _packMatchesQuery(StarDataPack pack, String keyword) {
  final haystack = StringBuffer()
    ..write(pack.mainSummaryText)
    ..write(' ')
    ..write(pack.secondarySummaryText ?? '');
  for (final item in pack.items) {
    haystack.write(' ');
    haystack.write(item.title);
    haystack.write(' ');
    haystack.write(item.subtitle);
    haystack.write(' ');
    haystack.write(item.source);
  }
  return haystack.toString().toLowerCase().contains(keyword);
}

List<StarDataPack> applyStarDataPackFilters(
  List<StarDataPack> packs, {
  StarDataCategory? category,
  StarDataGenre? genre,
  String? serviceId,
  String searchQuery = '',
}) {
  var filtered = filterStarDataPacksByCategory(packs, category);
  if (genre != null) {
    filtered = filtered.where((pack) => pack.resolvedGenre == genre).toList();
  }
  if (serviceId != null && serviceId != 'all') {
    filtered = filtered
        .where((pack) => pack.items.any((item) => item.source == serviceId))
        .toList();
  }
  if (searchQuery.trim().isNotEmpty) {
    filtered = searchStarDataPacks(filtered, searchQuery);
  }
  return filtered;
}

String formatStarDataPackDate(DateTime date) {
  final formatter = DateFormat('yyyy/MM/dd (E)');
  return formatter.format(date);
}
