/// Intake API v1.2.0 response models
/// Matches the backend IntakeResponse structure from Supabase Edge Function
class IntakeResponse {
  const IntakeResponse({
    required this.version,
    required this.items,
    this.health,
  });

  factory IntakeResponse.fromJson(Map<String, dynamic> json) {
    return IntakeResponse(
      version: json['version'] as String? ?? '1.0.0',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => IntakeItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      health: json['health'] != null
          ? IntakeHealth.fromJson(json['health'] as Map<String, dynamic>)
          : null,
    );
  }

  final String version;
  final List<IntakeItem> items;
  final IntakeHealth? health;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'items': items.map((item) => item.toJson()).toList(),
      if (health != null) 'health': health!.toJson(),
    };
  }
}

class IntakeItem {
  const IntakeItem({
    required this.title,
    required this.channel,
    required this.time,
    required this.videoId,
    required this.duration,
    required this.thumbnails,
  });

  factory IntakeItem.fromJson(Map<String, dynamic> json) {
    return IntakeItem(
      title: json['title'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      time: json['time'] as String?,
      videoId: json['videoId'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      thumbnails: json['thumbnails'] as Map<String, dynamic>? ?? {},
    );
  }

  final String title;
  final String channel;
  final String? time;
  final String videoId;
  final String duration;
  final Map<String, dynamic> thumbnails;

  /// Get thumbnail URL from thumbnails map
  String? get thumbnailUrl {
    if (thumbnails.isEmpty) return null;
    // Try common thumbnail keys
    return thumbnails['url'] as String? ??
        thumbnails['medium']?['url'] as String? ??
        thumbnails['default']?['url'] as String? ??
        thumbnails['high']?['url'] as String?;
  }

  /// Get YouTube watch URL
  String? get watchUrl {
    if (videoId.isEmpty) return null;
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'channel': channel,
      'time': time,
      'videoId': videoId,
      'duration': duration,
      'thumbnails': thumbnails,
    };
  }
}

class IntakeHealth {
  const IntakeHealth({
    required this.status,
    required this.version,
    required this.timestamp,
    required this.checks,
  });

  factory IntakeHealth.fromJson(Map<String, dynamic> json) {
    return IntakeHealth(
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '1.0.0',
      timestamp: json['timestamp'] as String? ?? '',
      checks: json['checks'] != null
          ? IntakeHealthChecks.fromJson(json['checks'] as Map<String, dynamic>)
          : const IntakeHealthChecks(),
    );
  }

  final String status;
  final String version;
  final String timestamp;
  final IntakeHealthChecks checks;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'version': version,
      'timestamp': timestamp,
      'checks': checks.toJson(),
    };
  }
}

class IntakeHealthChecks {
  const IntakeHealthChecks({
    this.rateLimit = 'unknown',
    this.metrics = 'unknown',
    this.llm = 'unknown',
  });

  factory IntakeHealthChecks.fromJson(Map<String, dynamic> json) {
    return IntakeHealthChecks(
      rateLimit: json['rate_limit'] as String? ?? 'unknown',
      metrics: json['metrics'] as String? ?? 'unknown',
      llm: json['llm'] as String? ?? 'unknown',
    );
  }

  final String rateLimit;
  final String metrics;
  final String llm;

  Map<String, dynamic> toJson() {
    return {
      'rate_limit': rateLimit,
      'metrics': metrics,
      'llm': llm,
    };
  }
}



