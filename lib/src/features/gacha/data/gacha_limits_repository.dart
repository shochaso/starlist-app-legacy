import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gacha_limits_models.dart';

/// ガチャ回数管理のリポジトリ
/// 
/// 新しいスキーマ（gacha_daily_attempts）に対応
/// - テーブル名: gacha_daily_attempts
/// - RPC関数パラメータ: target_user_id
/// - カラム: attempts（base/bonus/usedの区別なし）
class GachaLimitsRepository {
  final SupabaseClient _supabaseService;

  GachaLimitsRepository(SupabaseClient supabaseService) : _supabaseService = supabaseService;

  /// ガチャ回数の統計情報を取得
  /// 
  /// 新しいスキーマ（gacha_daily_attempts）を使用
  Future<GachaAttemptsStats> getGachaAttemptsStats(String userId) async {
    try {
      // 新しいスキーマでは、テーブルを直接参照
      return await _getStatsFromTable(userId);
    } catch (e) {
      // 例外時は初期化を試みてから再取得
      try {
        await initializeDailyAttempts(userId);
        return await _getStatsFromTable(userId);
      } catch (_) {
        return GachaAttemptsStats(
          baseAttempts: 0,
          bonusAttempts: 0,
          usedAttempts: 0,
          availableAttempts: 0,
          date: DateTime.now(),
        );
      }
    }
  }

  /// テーブルから統計情報を取得（新しいスキーマ対応）
  Future<GachaAttemptsStats> _getStatsFromTable(String userId) async {
    final today = _todayKeyJst3();
    final rows = await _supabaseService
        .from('gacha_daily_attempts')
        .select('date_key, attempts, updated_at')
        .eq('user_id', userId)
        .eq('date_key', today)
        .limit(1);

    if (rows.isNotEmpty) {
      final r = rows.first;
      final attempts = (r['attempts'] as int?) ?? 0;
      final dateKey = (r['date_key'] as String?) ?? today;
      final date = _parseDateKey(dateKey);
      
      // 新しいスキーマでは attempts のみ（base/bonus/used の区別なし）
      return GachaAttemptsStats(
        baseAttempts: 0,
        bonusAttempts: 0,
        usedAttempts: 0,
        availableAttempts: attempts,
        date: date,
      );
    }

    // 行が無ければ初期化してから再取得
    await initializeDailyAttempts(userId);
    final retryRows = await _supabaseService
        .from('gacha_daily_attempts')
        .select('date_key, attempts, updated_at')
        .eq('user_id', userId)
        .eq('date_key', today)
        .limit(1);

    if (retryRows.isNotEmpty) {
      final r = retryRows.first;
      final attempts = (r['attempts'] as int?) ?? 0;
      final dateKey = (r['date_key'] as String?) ?? today;
      final date = _parseDateKey(dateKey);
      
      return GachaAttemptsStats(
        baseAttempts: 0,
        bonusAttempts: 0,
        usedAttempts: 0,
        availableAttempts: attempts,
        date: date,
      );
    }

    return GachaAttemptsStats(
      baseAttempts: 0,
      bonusAttempts: 0,
      usedAttempts: 0,
      availableAttempts: 0,
      date: DateTime.now(),
    );
  }

  /// 日次ガチャ試行回数を初期化
  Future<void> initializeDailyAttempts(String userId) async {
    try {
      await _supabaseService.rpc('initialize_daily_gacha_attempts_jst3', params: {
        'target_user_id': userId,
      });
    } catch (e) {
      print('initialize_daily_gacha_attempts_jst3 failed: $e');
      rethrow;
    }
  }

  /// date_key (YYYYMMDD) を DateTime に変換
  DateTime _parseDateKey(String dateKey) {
    try {
      if (dateKey.length == 8) {
        final year = int.parse(dateKey.substring(0, 4));
        final month = int.parse(dateKey.substring(4, 6));
        final day = int.parse(dateKey.substring(6, 8));
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.now();
  }

  /// ガチャ回数を消費
  /// 
  /// 新しいスキーマ（gacha_daily_attempts）を使用
  Future<bool> consumeGachaAttempt(String userId) async {
    try {
      // RPC関数を使用（新しいスキーマ対応）
      final result = await _supabaseService
          .rpc('consume_gacha_attempt_atomic', params: {
            'target_user_id': userId,
          });

      // RPC関数はbooleanを返す
      if (result is bool) {
        return result;
      }
      
      // 念のため、Map形式の場合も対応
      if (result is Map<String, dynamic>) {
        return result['success'] == true;
      }
      
      return false;
    } catch (e) {
      print('consumeGachaAttempt failed: $e');
      return false;
    }
  }

  /// ガチャ結果を含めて原子的に消費＋履歴保存
  /// 
  /// 注意: 新しいスキーマでは、consume_gacha_attempt_atomicは
  /// gacha_result等のパラメータを受け取らないため、
  /// 消費後に別途履歴を記録する必要があります
  Future<bool> consumeAttemptWithResult(
    String userId,
    Map<String, dynamic> gachaResult, {
    int? rewardPoints,
    bool rewardSilverTicket = false,
  }) async {
    try {
      // 1. ガチャ回数を消費
      final consumed = await consumeGachaAttempt(userId);
      if (!consumed) {
        return false;
      }

      // 2. ガチャ履歴を記録（別途実装）
      await recordGachaResult(
        userId,
        gachaResult,
        1,
        'ad_gacha',
        rewardPoints: rewardPoints,
        rewardSilverTicket: rewardSilverTicket,
      );

      return true;
    } catch (e) {
      print('consumeAttemptWithResult failed: $e');
      return false;
    }
  }

  /// 最近の広告視聴記録を取得
  Future<List<AdView>> getRecentAdViews(String userId, {int limit = 10}) async {
    try {
      final result = await _supabaseService
          .from('ad_views')
          .select()
          .eq('user_id', userId)
          .order('viewed_at', ascending: false)
          .limit(limit);

      return (result as List)
          .map((json) => AdView.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 最近のガチャ履歴を取得
  Future<List<GachaHistory>> getRecentGachaHistory(String userId, {int limit = 20}) async {
    try {
      final result = await _supabaseService
          .from('gacha_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (result as List)
          .map((json) => GachaHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// ガチャ結果を履歴に記録
  Future<void> recordGachaResult(
    String userId,
    Map<String, dynamic> gachaResult,
    int attemptsUsed,
    String source, {
    int? rewardPoints,
    bool rewardSilverTicket = false,
  }) async {
    try {
      await _supabaseService.from('gacha_history').insert({
        'user_id': userId,
        'gacha_result': gachaResult,
        'attempts_used': attemptsUsed,
        'source': source,
        'created_at': DateTime.now().toIso8601String(),
        'reward_points': rewardPoints,
        'reward_silver_ticket': rewardSilverTicket,
      });
    } catch (e) {
      // エラー時はログ出力のみ（アプリの動作を止めたくない）
      print('Failed to record gacha history: $e');
    }
  }

  /// 今日のガチャ回数をリセット（デバッグ用）
  /// 
  /// 新しいスキーマ（gacha_daily_attempts）を使用
  Future<void> resetTodayAttempts(String userId) async {
    try {
      final todayKey = _todayKeyJst3();
      await _supabaseService
          .from('gacha_daily_attempts')
          .update({
            'attempts': 0,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('date_key', todayKey);
    } catch (e) {
      print('Failed to reset gacha attempts: $e');
      rethrow;
    }
  }

  /// 本日分のガチャ回数を設定（テスト用）
  /// 
  /// 新しいスキーマ（gacha_daily_attempts）を使用
  Future<void> setTodayBaseAttempts(String userId, int attempts) async {
    final todayKey = _todayKeyJst3();
    
    // 1) 初期化RPCを呼び出す
    try {
      await _supabaseService.rpc('initialize_daily_gacha_attempts_jst3', params: {
        'target_user_id': userId,
      });
    } catch (e) {
      print('initialize_daily_gacha_attempts_jst3 failed: $e');
      // 続行（upsertで作成される）
    }

    // 2) 本日分のattemptsを更新（なければupsert）
    try {
      await _supabaseService
          .from('gacha_daily_attempts')
          .upsert({
            'user_id': userId,
            'date_key': todayKey,
            'attempts': attempts,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,date_key');
    } catch (e) {
      print('setTodayBaseAttempts upsert failed: $e');
      rethrow;
    }
  }

  String _todayKeyJst3() {
    final nowJst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final shifted = nowJst.subtract(const Duration(hours: 3));
    return shifted.toIso8601String().split('T')[0];
  }
}
