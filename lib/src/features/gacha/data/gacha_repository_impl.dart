import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gacha_repository.dart';

/// GachaRepositoryImpl - GachaRepositoryの実装クラス
/// 
/// 最小仮実装（ビルドエラー解消用）
class GachaRepositoryImpl extends GachaRepository {
  GachaRepositoryImpl({Random? random, SupabaseClient? client}) 
      : super(
          client ?? Supabase.instance.client,
          random: random,
        );

  // GachaRepositoryのメソッドは既に実装されているため、
  // 追加の実装は不要（継承で利用可能）
}

