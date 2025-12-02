String buildPackId(String username, DateTime date) {
  final trimmedUsername = username.trim();
  if (trimmedUsername.isEmpty) {
    throw ArgumentError.value(username, 'username', 'must not be empty');
  }
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$trimmedUsername::$year-$month-$day';
}
