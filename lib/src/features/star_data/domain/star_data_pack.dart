import 'package:collection/collection.dart';

import 'star_data_item.dart';
import '../utils/star_data_category_definitions.dart';

class StarDataPack {
  const StarDataPack({
    required this.id,
    required this.starId,
    required this.date,
    required this.categoryCounts,
    required this.mainCategory,
    required this.mainSummaryText,
    required this.secondarySummaryText,
    required this.items,
    this.resolvedCategory,
    this.resolvedGenre,
  });

  final String id;
  final String starId;
  final DateTime date;
  final Map<String, int> categoryCounts;
  final String mainCategory;
  final String mainSummaryText;
  final String? secondarySummaryText;
  final List<StarDataItem> items;
  final StarDataCategory? resolvedCategory;
  final StarDataGenre? resolvedGenre;

  StarDataPack copyWith({
    String? id,
    String? starId,
    DateTime? date,
    Map<String, int>? categoryCounts,
    String? mainCategory,
    String? mainSummaryText,
    String? secondarySummaryText,
    List<StarDataItem>? items,
    StarDataCategory? resolvedCategory,
    StarDataGenre? resolvedGenre,
  }) {
    return StarDataPack(
      id: id ?? this.id,
      starId: starId ?? this.starId,
      date: date ?? this.date,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      mainCategory: mainCategory ?? this.mainCategory,
      mainSummaryText: mainSummaryText ?? this.mainSummaryText,
      secondarySummaryText: secondarySummaryText ?? this.secondarySummaryText,
      items: items ?? this.items,
      resolvedCategory: resolvedCategory ?? this.resolvedCategory,
      resolvedGenre: resolvedGenre ?? this.resolvedGenre,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StarDataPack &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            starId == other.starId &&
            date == other.date &&
            const MapEquality().equals(categoryCounts, other.categoryCounts) &&
            mainCategory == other.mainCategory &&
            mainSummaryText == other.mainSummaryText &&
            secondarySummaryText == other.secondarySummaryText &&
            const ListEquality().equals(items, other.items) &&
            resolvedCategory == other.resolvedCategory &&
            resolvedGenre == other.resolvedGenre;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      starId.hashCode ^
      date.hashCode ^
      const MapEquality().hash(categoryCounts) ^
      mainCategory.hashCode ^
      mainSummaryText.hashCode ^
      (secondarySummaryText?.hashCode ?? 0) ^
      const ListEquality().hash(items) ^
      resolvedCategory.hashCode ^
      resolvedGenre.hashCode;
}
