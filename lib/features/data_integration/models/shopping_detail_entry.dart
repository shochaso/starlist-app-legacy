import 'package:starlist_app/src/features/star_data/domain/star_data_item.dart';

class ShoppingDetailEntry {
  const ShoppingDetailEntry({
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
  final List<ShoppingDetailItem> items;

  factory ShoppingDetailEntry.fromStarDataItems({
    required List<StarDataItem> items,
    required String starId,
    String source = 'star_data',
  }) {
    if (items.isEmpty) {
      return ShoppingDetailEntry(
        id: '',
        starId: starId,
        createdAt: DateTime.now(),
        source: source,
        items: [],
      );
    }

    final shoppingItems = items
        .where((item) => item.category == 'shopping')
        .map((item) => ShoppingDetailItem.fromStarDataItem(item))
        .toList();

    return ShoppingDetailEntry(
      id: items.first.id,
      starId: starId,
      createdAt: items.first.createdAt,
      source: source,
      items: shoppingItems,
    );
  }

  factory ShoppingDetailEntry.fromStarDataItem(StarDataItem item) {
    return ShoppingDetailEntry(
      id: item.id,
      starId: item.starId,
      createdAt: item.createdAt,
      source: item.source,
      items: [ShoppingDetailItem.fromStarDataItem(item)],
    );
  }
}

class ShoppingDetailItem {
  const ShoppingDetailItem({
    required this.title,
    required this.shopName,
    this.price,
    this.category,
  });

  final String title;
  final String shopName;
  final String? price;
  final String? category;

  factory ShoppingDetailItem.fromStarDataItem(StarDataItem item) {
    // raw_payloadから詳細情報を取得
    final extra = item.extra;
    final price = extra?['price'] as String?;
    final category = extra?['category'] as String?;

    return ShoppingDetailItem(
      title: item.title,
      shopName: item.subtitle.isNotEmpty ? item.subtitle : '不明なショップ',
      price: price,
      category: category ?? item.genre,
    );
  }
}


