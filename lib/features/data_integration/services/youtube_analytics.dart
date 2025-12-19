import 'package:flutter/foundation.dart';

/// Lightweight data integration analytics stub.
class YoutubeAnalytics {
  YoutubeAnalytics._();

  static Future<void> logCardDetailTap({
    required String source,
    required int videoCount,
    required DateTime createdAt,
  }) async {
    await _safeLog(
      name: 'youtube_watch_card_detail_tap',
      parameters: {
        'source': source,
        'video_count': videoCount,
        'created_bucket': _relativeBucket(createdAt),
      },
    );
  }

  static Future<void> logDetailOpen({
    required String source,
    required int videoCount,
    required bool firstVideoHasUrl,
  }) async {
    await _safeLog(
      name: 'youtube_watch_detail_open',
      parameters: {
        'source': source,
        'video_count': videoCount,
        'first_video_has_url': firstVideoHasUrl,
      },
    );
  }

  static Future<void> logDetailOpenYoutube({
    required String source,
    required int videoCount,
  }) async {
    await _safeLog(
      name: 'youtube_watch_detail_open_youtube',
      parameters: {
        'source': source,
        'video_count': videoCount,
      },
    );
  }

  static Future<void> _safeLog({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      debugPrint('YouTubeAnalytics $name: $parameters');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('YoutubeAnalytics log failed: $error');
      }
    }
  }

  static String _relativeBucket(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inHours < 24) return 'today';
    if (difference.inHours < 48) return 'yesterday';
    return 'older';
  }

  /// Shopping / Music event helpers
  static Future<void> logShoppingCardDetailTap({
    required String source,
    required String starId,
    required int totalItems,
  }) =>
      _safeLog(
        name: 'shopping_card_detail_tap',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_items': totalItems,
        },
      );

  static Future<void> logShoppingDetailOpen({
    required String source,
    required String starId,
    required int totalItems,
  }) =>
      _safeLog(
        name: 'shopping_detail_open',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_items': totalItems,
        },
      );

  static Future<void> logShoppingDetailOpenExternal({
    required String source,
    required String starId,
    required int totalItems,
    required String url,
  }) =>
      _safeLog(
        name: 'shopping_detail_open_external',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_items': totalItems,
          'external_url': url,
        },
      );

  static Future<void> logShoppingDetailPlanCta({
    required String source,
    required String starId,
    required int totalItems,
  }) =>
      _safeLog(
        name: 'shopping_detail_plan_cta',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_items': totalItems,
        },
      );

  static Future<void> logMusicCardDetailTap({
    required String source,
    required String starId,
    required int totalTracks,
  }) =>
      _safeLog(
        name: 'music_card_detail_tap',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_tracks': totalTracks,
        },
      );

  static Future<void> logMusicDetailOpen({
    required String source,
    required String starId,
    required int totalTracks,
  }) =>
      _safeLog(
        name: 'music_detail_open',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_tracks': totalTracks,
        },
      );

  static Future<void> logMusicDetailOpenExternal({
    required String source,
    required String starId,
    required int totalTracks,
    required String url,
  }) =>
      _safeLog(
        name: 'music_detail_open_external',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_tracks': totalTracks,
          'external_url': url,
        },
      );

  static Future<void> logMusicDetailPlanCta({
    required String source,
    required String starId,
    required int totalTracks,
  }) =>
      _safeLog(
        name: 'music_detail_plan_cta',
        parameters: {
          'source': source,
          'star_id': starId,
          'total_tracks': totalTracks,
        },
      );
}



