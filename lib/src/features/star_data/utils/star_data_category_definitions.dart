enum StarDataCategory {
  youtube,
  video,
  shopping,
  music,
  receipt,
  other;

  String get label {
    switch (this) {
      case StarDataCategory.youtube:
        return 'YouTube';
      case StarDataCategory.video:
        return '動画';
      case StarDataCategory.shopping:
        return 'ショッピング';
      case StarDataCategory.music:
        return '音楽';
      case StarDataCategory.receipt:
        return 'レシート';
      case StarDataCategory.other:
        return 'その他';
    }
  }

  static StarDataCategory fromString(String? value) {
    return StarDataCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => StarDataCategory.other,
    );
  }
}

enum StarDataGenre {
  // YouTube
  videoVariety,
  videoVlog,
  videoReview,
  videoLive,
  videoAsmr,
  videoBgm,
  
  // Shopping
  shoppingWork,
  shoppingFood,
  shoppingFashion,
  shoppingDaily,

  // Music
  musicWork,
  musicJpop,
  musicAnime,
  musicLofi,

  // Receipt
  receiptConvenience,
  receiptSupermarket,
  
  // Other
  other;

  String get label {
    switch (this) {
      case StarDataGenre.videoVariety:
        return 'バラエティ';
      case StarDataGenre.videoVlog:
        return 'Vlog';
      case StarDataGenre.videoReview:
        return 'レビュー';
      case StarDataGenre.videoLive:
        return 'ライブ配信';
      case StarDataGenre.videoAsmr:
        return 'ASMR';
      case StarDataGenre.videoBgm:
        return 'BGM';
      case StarDataGenre.shoppingWork:
        return '仕事用品';
      case StarDataGenre.shoppingFood:
        return '食料品';
      case StarDataGenre.shoppingFashion:
        return 'ファッション';
      case StarDataGenre.shoppingDaily:
        return '日用品';
      case StarDataGenre.musicWork:
        return '作業用BGM';
      case StarDataGenre.musicJpop:
        return 'J-POP';
      case StarDataGenre.musicAnime:
        return 'アニソン';
      case StarDataGenre.musicLofi:
        return 'Lo-fi';
      case StarDataGenre.receiptConvenience:
        return 'コンビニ';
      case StarDataGenre.receiptSupermarket:
        return 'スーパー';
      case StarDataGenre.other:
        return 'その他';
    }
  }

  static StarDataGenre fromString(String? value) {
    if (value == null) return StarDataGenre.other;
    switch (value) {
      case 'video_variety': return StarDataGenre.videoVariety;
      case 'video_vlog': return StarDataGenre.videoVlog;
      case 'video_review': return StarDataGenre.videoReview;
      case 'video_live': return StarDataGenre.videoLive;
      case 'video_asmr': return StarDataGenre.videoAsmr;
      case 'video_bgm': return StarDataGenre.videoBgm;
      case 'shopping_work': return StarDataGenre.shoppingWork;
      case 'shopping_food': return StarDataGenre.shoppingFood;
      case 'shopping_fashion': return StarDataGenre.shoppingFashion;
      case 'shopping_daily': return StarDataGenre.shoppingDaily;
      case 'music_work': return StarDataGenre.musicWork;
      case 'music_jpop': return StarDataGenre.musicJpop;
      case 'music_anime': return StarDataGenre.musicAnime;
      case 'music_lofi': return StarDataGenre.musicLofi;
      case 'receipt_convenience': return StarDataGenre.receiptConvenience;
      case 'receipt_supermarket': return StarDataGenre.receiptSupermarket;
      default: return StarDataGenre.other;
    }
  }
}

const Map<StarDataCategory, List<StarDataGenre>> categoryToGenres = {
  StarDataCategory.youtube: [
    StarDataGenre.videoVariety,
    StarDataGenre.videoVlog,
    StarDataGenre.videoReview,
    StarDataGenre.videoLive,
    StarDataGenre.videoAsmr,
    StarDataGenre.videoBgm,
  ],
  StarDataCategory.video: [
    StarDataGenre.videoVariety,
    StarDataGenre.videoVlog,
    StarDataGenre.videoReview,
    StarDataGenre.videoLive,
    StarDataGenre.videoAsmr,
    StarDataGenre.videoBgm,
  ],
  StarDataCategory.shopping: [
    StarDataGenre.shoppingWork,
    StarDataGenre.shoppingFood,
    StarDataGenre.shoppingFashion,
    StarDataGenre.shoppingDaily,
  ],
  StarDataCategory.music: [
    StarDataGenre.musicWork,
    StarDataGenre.musicJpop,
    StarDataGenre.musicAnime,
    StarDataGenre.musicLofi,
  ],
  StarDataCategory.receipt: [
    StarDataGenre.receiptConvenience,
    StarDataGenre.receiptSupermarket,
  ],
  StarDataCategory.other: [],
};
