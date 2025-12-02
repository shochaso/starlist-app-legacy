String mapStarDataCategoryLabel(String value) {
  switch (value) {
    case 'youtube':
      return 'YouTube';
    case 'video':
      return '動画';
    case 'shopping':
      return 'ショッピング';
    case 'music':
      return '音楽';
    case 'receipt':
      return 'レシート';
    default:
      return 'その他';
  }
}
