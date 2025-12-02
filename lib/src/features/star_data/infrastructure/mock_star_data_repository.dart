import 'package:uuid/uuid.dart';
import '../domain/star_data_item.dart';
import '../domain/star_data_repository.dart';

/// Mock repository for local development and fallback scenarios.
/// In production, use SupabaseStarDataRepository with actual data.
class MockStarDataRepository implements StarDataRepository {
  MockStarDataRepository();

  static const _hanayama = 'star_hanayama_mizuki';
  static const _kato = 'star_kato_junichi';

  @override
  Future<List<StarDataItem>> getStarData({
    required String starId,
    int limit = 50,
  }) async {
    return fetchStarData(starId: starId, limit: limit);
  }

  @override
  Future<List<StarDataItem>> fetchStarData({
    required String starId,
    int limit = 50,
  }) async {
    // Return data for specific stars, fallback to Hanayama Mizuki for unknown stars
    List<StarDataItem> base;
    if (starId == _hanayama) {
      base = _hanayamaData;
    } else if (starId == _kato) {
      base = _katoData;
    } else {
      // Fallback to Hanayama Mizuki data for unknown stars
      base = _hanayamaData;
    }
    return base
        .where((item) => !_hiddenItemIds.contains(item.id))
        .take(limit)
        .toList();
  }

  static final List<StarDataItem> _hanayamaData = [
    // Day 0 (Today)
    ...List.generate(12, (index) => StarDataItem(
      id: const Uuid().v4(),
      starId: _hanayama,
      date: DateTime.now().subtract(Duration(minutes: index * 30)),
      category: 'youtube',
      genre: index % 2 == 0 ? 'video_variety' : 'video_vlog',
      title: 'YouTube視聴動画 ${index + 1}',
      subtitle: '視聴日: ${DateTime.now().toIso8601String()}',
      source: 'youtube',
      createdAt: DateTime.now(),
    )),
    
    // Day 1 (Yesterday) - Shopping
    ...List.generate(3, (index) => StarDataItem(
      id: const Uuid().v4(),
      starId: _hanayama,
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      category: 'shopping',
      genre: index == 0 ? 'shopping_food' : 'shopping_daily',
      title: index == 0 ? 'コンビニで朝食購入' : '日用品の買い出し',
      subtitle: '購入日: ${DateTime.now().subtract(const Duration(days: 1)).toIso8601String()}',
      source: 'amazon',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    )),

    // Day 2 - Music
    ...List.generate(5, (index) => StarDataItem(
      id: const Uuid().v4(),
      starId: _hanayama,
      date: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      category: 'music',
      genre: 'music_jpop',
      title: 'J-POPプレイリスト再生',
      subtitle: '再生日: ${DateTime.now().subtract(const Duration(days: 2)).toIso8601String()}',
      source: 'spotify',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    )),

    // Day 3 - Receipt
    ...List.generate(4, (index) => StarDataItem(
      id: const Uuid().v4(),
      starId: _hanayama,
      date: DateTime.now().subtract(const Duration(days: 3, hours: 4)),
      category: 'receipt',
      genre: 'receipt_supermarket',
      title: 'スーパーで食材購入',
      subtitle: '購入日: ${DateTime.now().subtract(const Duration(days: 3)).toIso8601String()}',
      source: 'receipt_supermarket',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    )),

    // Day 4 - YouTube (ASMR)
    ...List.generate(2, (index) => StarDataItem(
      id: const Uuid().v4(),
      starId: _hanayama,
      date: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
      category: 'youtube',
      genre: 'video_asmr',
      title: 'ASMR動画視聴',
      subtitle: '視聴日: ${DateTime.now().subtract(const Duration(days: 4)).toIso8601String()}',
      source: 'youtube',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    )),
  ];

  // Mock data for Kato Junichi (local fallback only; Supabase seed is primary)
  static final List<StarDataItem> _katoData = List.generate(
    10,
    (index) => StarDataItem(
      id: const Uuid().v4(),
      starId: _kato,
      date: DateTime.now().subtract(Duration(hours: index * 4)),
      category: index % 3 == 0
          ? 'youtube'
          : index % 3 == 1
              ? 'shopping'
              : 'music',
      genre: index % 3 == 0
          ? 'video_variety'
          : index % 3 == 1
              ? 'shopping_work'
              : 'music_work',
      title: index % 3 == 0
          ? '【生放送】ゲーム配信 ${index + 1}'
          : index % 3 == 1
              ? 'ゲーム周辺機器購入 ${index + 1}'
              : 'BGMプレイリスト ${index + 1}',
      subtitle: index % 3 == 0
          ? 'ソウルライク系ゲーム配信'
          : index % 3 == 1
              ? 'コントローラー / ヘッドセット'
              : '作業用BGM',
      source: index % 3 == 0 ? 'youtube' : index % 3 == 1 ? 'amazon' : 'spotify',
      createdAt: DateTime.now().subtract(Duration(hours: index * 3)),
      extra: {
        'notes': 'Sample entry $index for Kato Junichi (local fallback)',
      },
    ),
  );

  @override
  Future<void> saveStarDataItem(StarDataItem item) async {
    // No-op for mock; log for visibility
    print('[MockStarDataRepository] saveStarDataItem for ${item.starId}: ${item.title}');
  }

  @override
  Future<void> hideStarDataItem({
    required String id,
    required String starId,
  }) async {
    _hiddenItemIds.add(id);
  }

  final _hiddenItemIds = <String>{};
}
