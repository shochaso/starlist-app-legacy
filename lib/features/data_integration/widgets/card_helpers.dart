/// Shared helper functions for data integration cards.
/// Contains truncate logic and relative time formatting used across YouTube, Shopping, and Music cards.

/// タイトル/商品名/曲名などの主要テキストを 15 文字以内に丸める。
String truncateForTitle(String value) => _truncateWithEllipsis(value, 15);

/// 右側の補助テキスト（チャンネル名・ショップ名・アーティスト名）を 10 文字以内に丸める。
String truncateForChannel(String value) => _truncateWithEllipsis(value, 10);

String _truncateWithEllipsis(String value, int limit) {
  final trimmed = value.trim();
  final codePoints = trimmed.runes.toList();
  if (codePoints.length <= limit) return trimmed;
  final truncated = String.fromCharCodes(codePoints.take(limit));
  return '$truncated…';
}

/// `<24h` は時間、それ以外は日単位で丸めて表示。
/// 負の duration は 0 として扱う。
String formatRelativeTime(DateTime createdAt, DateTime now) {
  final difference = now.difference(createdAt);
  final positiveDifference = difference.isNegative ? Duration.zero : difference;
  if (positiveDifference < const Duration(hours: 24)) {
    final hours = positiveDifference.inHours;
    final displayHours = hours < 1 ? 1 : hours;
    return '${displayHours}時間前';
  }
  final days = positiveDifference.inDays;
  final displayDays = days < 1 ? 1 : days;
  return '${displayDays}日前';
}

