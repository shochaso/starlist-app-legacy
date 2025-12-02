import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';

class MusicDetailEntry {
  const MusicDetailEntry({
    required this.id,
    required this.starId,
    required this.createdAt,
    required this.source,
    required this.items,
  });

  final String id;
  final String starId;
  final DateTime createdAt;
  final String source;
  final List<MusicDetailItem> items;

  factory MusicDetailEntry.fromStarDataItems({
    required List<StarDataItem> items,
    required String starId,
    String source = 'star_data',
  }) {
    if (items.isEmpty) {
      return MusicDetailEntry(
        id: '',
        starId: starId,
        createdAt: DateTime.now(),
        source: source,
        items: [],
      );
    }

    final musicItems = items
        .where((item) => item.category == 'music')
        .map((item) => MusicDetailItem.fromStarDataItem(item))
        .toList();

    return MusicDetailEntry(
      id: items.first.id,
      starId: starId,
      createdAt: items.first.createdAt,
      source: source,
      items: musicItems,
    );
  }

  factory MusicDetailEntry.fromStarDataItem(StarDataItem item) {
    return MusicDetailEntry(
      id: item.id,
      starId: item.starId,
      createdAt: item.createdAt,
      source: item.source,
      items: [MusicDetailItem.fromStarDataItem(item)],
    );
  }
}

class MusicDetailItem {
  const MusicDetailItem({
    required this.title,
    required this.artist,
    this.album,
    this.service,
  });

  final String title;
  final String artist;
  final String? album;
  final String? service;

  factory MusicDetailItem.fromStarDataItem(StarDataItem item) {
    // raw_payloadから詳細情報を取得
    final extra = item.extra;
    final album = extra?['album'] as String?;
    final service = extra?['service'] as String?;

    return MusicDetailItem(
      title: item.title,
      artist: item.subtitle.isNotEmpty ? item.subtitle : '不明なアーティスト',
      album: album,
      service: service ?? item.source,
    );
  }
}


