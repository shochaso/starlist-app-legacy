import '../models/star_data_item.dart';
import '../models/star_data_pack.dart';
import '../models/star_data_summary.dart';

abstract class StarDataRepository {
  Future<List<StarDataItem>> fetchItems({
    required String username,
    required DateTime date,
    String? category,
    String? genre,
  });

  Future<StarDataPack> fetchPack(String packId);

  Future<void> hideItem(String itemId);

  Future<StarDataSummary> fetchSummary(String username);
}
