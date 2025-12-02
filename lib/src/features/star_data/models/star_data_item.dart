import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'star_category.dart';
import 'star_genre.dart';

@immutable
class StarDataItem {
  const StarDataItem({
    required this.id,
    required this.username,
    required this.date,
    required this.category,
    this.genre,
    required this.title,
    this.thumbnailUrl,
    this.metadata,
  });

  final String id;
  final String username;
  final DateTime date;
  final StarCategory category;
  final StarGenre? genre;
  final String title;
  final String? thumbnailUrl;
  final Map<String, dynamic>? metadata;

  factory StarDataItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? payload = _extractMetadata(json);
    final thumbnail = _extractThumbnail(json, payload);
    final date =
        _parseDate(json['date'] ?? json['occurred_at']) ?? DateTime.now();
    final catValue = (json['category'] as String?) ?? '';
    return StarDataItem(
      id: (json['id'] ?? '') as String,
      username: (json['username'] ?? json['star_id'] ?? '') as String,
      date: date,
      category: StarCategory.fromValue(catValue.isEmpty ? 'other' : catValue),
      genre: _extractGenre(json),
      title: (json['title'] ?? '') as String,
      thumbnailUrl: thumbnail,
      metadata: payload,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'date': date.toIso8601String(),
        'category': category.value,
        'genre': genre?.value,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'metadata': metadata,
      };

  static StarGenre? _extractGenre(Map<String, dynamic> json) {
    final rawGenre = json['genre'];
    if (rawGenre is String && rawGenre.isNotEmpty) {
      return StarGenre.fromValue(rawGenre);
    }
    return null;
  }

  static Map<String, dynamic>? _extractMetadata(Map<String, dynamic> json) {
    final raw = json['metadata'] ?? json['raw_payload'];
    if (raw == null) {
      return null;
    }
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // fall through to null
      }
    }
    return null;
  }

  static String? _extractThumbnail(
    Map<String, dynamic> json,
    Map<String, dynamic>? metadata,
  ) {
    final direct = json['thumbnailUrl'] ?? json['thumbnail_url'];
    if (direct is String && direct.isNotEmpty) {
      return direct;
    }
    final metaValue = metadata?['thumbnail_url'];
    if (metaValue is String && metaValue.isNotEmpty) {
      return metaValue;
    }
    return null;
  }

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
