import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:starlist_app/providers/youtube_history_provider.dart';
import 'intake_response.dart';

/// Represents a single video entry shown on the detail screen.
@immutable
class YoutubeWatchDetailEntry {
  const YoutubeWatchDetailEntry({
    required this.title,
    required this.channel,
    this.duration,
    this.watchUrl,
    this.thumbnailUrl,
    required this.addedAt,
  });

  final String title;
  final String channel;
  final String? duration;
  final String? watchUrl;
  final String? thumbnailUrl;
  final DateTime addedAt;

  /// Builds entry from YouTubeHistoryItem (imported history).
  factory YoutubeWatchDetailEntry.fromHistoryItem(YouTubeHistoryItem item) {
    return YoutubeWatchDetailEntry(
      title: item.title,
      channel: item.channel,
      duration: item.duration,
      watchUrl: item.url,
      thumbnailUrl: item.thumbnailUrl,
      addedAt: item.addedAt,
    );
  }

  /// Builds entry from Intake API response item.
  factory YoutubeWatchDetailEntry.fromIntakeItem(IntakeItem item) {
    return YoutubeWatchDetailEntry(
      title: item.title,
      channel: item.channel,
      duration: item.duration,
      watchUrl: item.watchUrl,
      thumbnailUrl: item.thumbnailUrl,
      addedAt: DateTime.tryParse(item.time ?? '') ?? DateTime.now(),
    );
  }

  String get formattedAddedAt {
    return DateFormat('yyyy/MM/dd HH:mm').format(addedAt);
  }
}

/// Arguments passed to the YouTube detail screen.
@immutable
class YoutubeWatchDetailArgs {
  const YoutubeWatchDetailArgs({
    required this.entries,
    required this.createdAt,
    required this.label,
    this.subtitle,
    this.sourceLabel,
  });

  final List<YoutubeWatchDetailEntry> entries;
  final DateTime createdAt;
  final String label;
  final String? subtitle;
  final String? sourceLabel;
}



