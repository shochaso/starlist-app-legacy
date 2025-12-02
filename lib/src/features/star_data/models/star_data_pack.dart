import 'package:flutter/foundation.dart';

import 'star_data_item.dart';

@immutable
class StarDataPack {
  const StarDataPack({
    required this.packId,
    required this.items,
    required this.createdAt,
  });

  final String packId;
  final List<StarDataItem> items;
  final DateTime createdAt;

  factory StarDataPack.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ??
        (json['items_json'] as List<dynamic>?) ??
        [];
    final parsedItems = rawItems
        .where((entry) => entry is Map<String, dynamic>)
        .cast<Map<String, dynamic>>()
        .map((entry) => StarDataItem.fromJson(entry))
        .toList();
    final date =
        _parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now();
    return StarDataPack(
      packId: (json['packId'] ?? json['pack_id'] ?? '') as String,
      items: parsedItems,
      createdAt: date,
    );
  }

  Map<String, dynamic> toJson() => {
        'packId': packId,
        'items': items.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
