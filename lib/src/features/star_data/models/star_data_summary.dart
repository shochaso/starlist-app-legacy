import 'package:flutter/foundation.dart';

import 'star_category.dart';

@immutable
class StarDataSummary {
  const StarDataSummary({
    required this.dailyCount,
    required this.weeklyCount,
    required this.monthlyCount,
    required this.latestCategories,
  });

  final int dailyCount;
  final int weeklyCount;
  final int monthlyCount;
  final List<StarCategory> latestCategories;

  factory StarDataSummary.fromJson(Map<String, dynamic> json) {
    final categories = (json['latest_categories'] ?? json['latestCategories'])
            as List<dynamic>? ??
        [];
    return StarDataSummary(
      dailyCount: _parseCount(json['daily_count'] ?? json['dailyCount']),
      weeklyCount: _parseCount(json['weekly_count'] ?? json['weeklyCount']),
      monthlyCount: _parseCount(json['monthly_count'] ?? json['monthlyCount']),
      latestCategories:
          categories.whereType<String>().map(StarCategory.fromValue).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'daily_count': dailyCount,
        'weekly_count': weeklyCount,
        'monthly_count': monthlyCount,
        'latest_categories':
            latestCategories.map((category) => category.value).toList(),
      };

  static int _parseCount(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
