import 'package:flutter/foundation.dart';

// YouTube analytics (既存互換)
void logYoutubeCardDetailTap({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] YouTube card detail tap: starId=$starId, totalCount=$totalCount, source=$source');
}

void logYoutubeDetailOpen({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] YouTube detail open: starId=$starId, totalCount=$totalCount, source=$source');
}

void logYoutubeDetailPlanCta({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] YouTube detail plan CTA: starId=$starId, totalCount=$totalCount, source=$source');
}

// Shopping analytics
void logShoppingCardDetailTap({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] Shopping card detail tap: starId=$starId, totalCount=$totalCount, source=$source');
}

void logShoppingDetailOpen({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] Shopping detail open: starId=$starId, totalCount=$totalCount, source=$source');
}

void logShoppingDetailPlanCta({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] Shopping detail plan CTA: starId=$starId, totalCount=$totalCount, source=$source');
}

// Music analytics
void logMusicCardDetailTap({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] Music card detail tap: starId=$starId, totalCount=$totalCount, source=$source');
}

void logMusicDetailOpen({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] Music detail open: starId=$starId, totalCount=$totalCount, source=$source');
}

void logMusicDetailPlanCta({
  required String starId,
  required int totalCount,
  required String source,
}) {
  debugPrint('[Analytics] Music detail plan CTA: starId=$starId, totalCount=$totalCount, source=$source');
}



