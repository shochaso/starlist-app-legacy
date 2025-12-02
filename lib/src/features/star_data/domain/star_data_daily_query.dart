import 'package:flutter/foundation.dart';

@immutable
class StarDataDailyQuery {
  StarDataDailyQuery({
    required this.starId,
    required DateTime dateOnly,
    this.category,
  }) : dateOnly = DateTime(dateOnly.year, dateOnly.month, dateOnly.day);

  final String starId;
  final DateTime dateOnly;
  final String? category;
}
