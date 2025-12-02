import 'package:flutter/foundation.dart';

@immutable
class StarCategory {
  const StarCategory._(this.value);

  const StarCategory(String value) : this._(value);

  final String value;

  /// Known category constants to make comparisons easier.
  static const youtube = StarCategory._('youtube');
  static const shopping = StarCategory._('shopping');
  static const music = StarCategory._('music');
  static const receipt = StarCategory._('receipt');
  static const travel = StarCategory._('travel');
  static const wellness = StarCategory._('wellness');
  static const community = StarCategory._('community');
  static const art = StarCategory._('art');
  static const food = StarCategory._('food');
  static const lifestyle = StarCategory._('lifestyle');
  static const other = StarCategory._('other');

  static const Map<String, StarCategory> _known = {
    'youtube': youtube,
    'shopping': shopping,
    'music': music,
    'receipt': receipt,
    'travel': travel,
    'wellness': wellness,
    'community': community,
    'art': art,
    'food': food,
    'lifestyle': lifestyle,
    'other': other,
  };

  /// Creates a category from any string, normalizing to a known constant when possible.
  factory StarCategory.fromValue(String value) {
    final normalized = value.toLowerCase();
    return _known[normalized] ?? StarCategory(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StarCategory && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
