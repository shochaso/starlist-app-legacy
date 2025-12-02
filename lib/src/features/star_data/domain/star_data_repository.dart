import 'package:flutter/foundation.dart';
import 'star_data_item.dart';

abstract class StarDataRepository {
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  });

  /// Inserts a StarDataItem into the backing store.
  Future<void> saveStarDataItem(StarDataItem item);

  /// Soft delete a StarDataItem so that it is hidden from all listings.
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  });

  @protected
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  });
}

