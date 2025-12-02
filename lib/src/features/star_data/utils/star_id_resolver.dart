/// Utility functions for resolving starId from username or other identifiers.
/// In production, this should query the profiles table to get the actual user ID.
class StarIdResolver {
  StarIdResolver._();

  /// Converts a username to a starId format used by repositories.
  /// Maps known stars to their starId, falls back to Hanayama Mizuki for unknown usernames.
  /// 
  /// Known stars:
  /// - 'hanayama-mizuki' / '花山瑞樹' -> 'star_hanayama_mizuki'
  /// - 'kato-junichi' / '加藤純一' -> 'star_kato_junichi'
  /// - Unknown -> 'star_hanayama_mizuki' (fallback)
  static String usernameToStarId(String username) {
    // Normalize username (remove spaces, convert to lowercase)
    final normalized = username.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '-');

    // Known star mappings
    if (normalized == 'hanayama-mizuki' || normalized == '花山瑞樹' || normalized == 'hanayamamizuki') {
      return 'star_hanayama_mizuki';
    }
    if (normalized == 'kato-junichi' || normalized == '加藤純一' || normalized == 'katojunichi') {
      return 'star_kato_junichi';
    }

    // In production, query profiles table to get actual star_id
    // For now, fallback to Hanayama Mizuki for unknown usernames
    // Note: This should be replaced with actual Supabase query in production
    return 'star_hanayama_mizuki';
  }

  /// Resolves starId from current user context.
  /// Falls back to Hanayama Mizuki if user is not logged in, not a star, or username is missing.
  static String currentUserStarId({
    required bool isLoggedIn,
    required bool isStar,
    String? username,
  }) {
    if (!isLoggedIn || !isStar || username == null || username.isEmpty) {
      // Fallback to Hanayama Mizuki
      return 'star_hanayama_mizuki';
    }
    return usernameToStarId(username);
  }
}
