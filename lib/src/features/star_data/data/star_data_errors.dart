enum StarDataErrorCode {
  fetchItems,
  fetchPack,
  hideItem,
  fetchSummary,
  mockData,
}

class StarDataError implements Exception {
  const StarDataError(this.code, [this.message]);

  final StarDataErrorCode code;
  final String? message;

  factory StarDataError.fetchItems([String? message]) =>
      StarDataError(StarDataErrorCode.fetchItems, message);
  factory StarDataError.fetchPack([String? message]) =>
      StarDataError(StarDataErrorCode.fetchPack, message);
  factory StarDataError.hideItem([String? message]) =>
      StarDataError(StarDataErrorCode.hideItem, message);
  factory StarDataError.fetchSummary([String? message]) =>
      StarDataError(StarDataErrorCode.fetchSummary, message);
  factory StarDataError.mockData([String? message]) =>
      StarDataError(StarDataErrorCode.mockData, message);

  @override
  String toString() {
    final detail = message != null ? ': $message' : '';
    return 'StarDataError.${code.name}$detail';
  }
}
