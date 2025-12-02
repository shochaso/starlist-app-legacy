import 'package:flutter/foundation.dart';

@immutable
class StarGenre {
  const StarGenre._(this.value);

  const StarGenre(String value) : this._(value);

  final String value;

  static const videoVariety = StarGenre._('video_variety');
  static const videoGameplay = StarGenre._('video_gameplay');
  static const videoBgm = StarGenre._('video_bgm');
  static const shoppingGroceries = StarGenre._('shopping_groceries');
  static const shoppingGadget = StarGenre._('shopping_gadget');
  static const musicPop = StarGenre._('music_pop');
  static const musicLofi = StarGenre._('music_lofi');
  static const travelGear = StarGenre._('travel_gear');
  static const wellnessRoutine = StarGenre._('wellness_routine');
  static const communityChat = StarGenre._('community_chat');
  static const sunburst = StarGenre._('sunburst');

  static const Map<String, StarGenre> _known = {
    'video_variety': videoVariety,
    'video_gameplay': videoGameplay,
    'video_bgm': videoBgm,
    'shopping_groceries': shoppingGroceries,
    'shopping_gadget': shoppingGadget,
    'music_pop': musicPop,
    'music_lofi': musicLofi,
    'travel_gear': travelGear,
    'wellness_routine': wellnessRoutine,
    'community_chat': communityChat,
    'sunburst': sunburst,
  };

  /// Creates a genre from any string, normalizing to a known constant when possible.
  factory StarGenre.fromValue(String value) {
    final normalized = value.toLowerCase();
    return _known[normalized] ?? StarGenre(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is StarGenre && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
