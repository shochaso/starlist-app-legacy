class StarDataItem {
  StarDataItem({
    required this.id,
    required this.starId,
    required this.date,
    required this.category,
    required this.genre,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.createdAt,
    this.isHidden = false,
    this.extra,
  });

  final String id;
  final String starId;
  final DateTime date;
  final String category;
  final String genre;
  final String title;
  final String subtitle;
  final String source;
  final DateTime createdAt;
  final bool isHidden;
  final Map<String, dynamic>? extra;

  factory StarDataItem.fromJson(Map<String, dynamic> json) => StarDataItem(
        id: json['id'] as String? ?? '',
        starId: json['star_id'] as String? ?? '',
        date: DateTime.tryParse(json['occurred_at'] as String? ?? '') ?? DateTime.now(),
        category: json['category'] as String? ?? '',
        genre: json['genre'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        source: json['source'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        isHidden: json['is_hidden'] as bool? ?? false,
        extra: json['raw_payload'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'star_id': starId,
        'category': category,
        'genre': genre,
        'title': title,
        'subtitle': subtitle,
        'source': source,
        'occurred_at': date.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'is_hidden': isHidden,
        'raw_payload': extra,
      };
}


