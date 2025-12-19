import 'package:supabase_flutter/supabase_flutter.dart';

/// ガチャ機能のリポジトリ（修正版）
/// 
/// 修正内容:
/// - RPC関数のパラメータ追加（target_user_id）
/// - 戻り値型の修正（void関数の適切な処理）
/// - エラーハンドリングの追加
class GachaRepository {
  final SupabaseClient client;

  GachaRepository(this.client);

  /// 日次ガチャ試行回数を初期化
  /// 
  /// 戻り値: void（成功時は例外なし、失敗時は例外をスロー）
  Future<void> initDailyAttempts(String userId) async {
    try {
      await client.rpc('initialize_daily_gacha_attempts_jst3', params: {
        'target_user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to initialize daily gacha attempts: $e');
    }
  }

  /// 広告視聴を完了してチケットを付与
  /// 
  /// 戻り値: void（成功時は例外なし、失敗時は例外をスロー）
  Future<void> recordAdViewAndGrant(String userId) async {
    try {
      await client.rpc('complete_ad_view_and_grant_ticket', params: {
        'target_user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to record ad view and grant ticket: $e');
    }
  }

  /// ガチャ試行回数を消費
  /// 
  /// 戻り値: true（消費成功）、false（消費失敗：回数不足）
  Future<bool> consume(String userId) async {
    try {
      final result = await client.rpc('consume_gacha_attempt_atomic', params: {
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
      throw Exception('Failed to consume gacha attempt: $e');
    }
  }

  /// 現在のユーザーIDを取得（ヘルパーメソッド）
  /// 
  /// 注意: このメソッドは認証済みユーザーのIDを取得します
  String? getCurrentUserId() {
    return client.auth.currentUser?.id;
  }

  /// 現在のユーザーで日次ガチャ試行回数を初期化（便利メソッド）
  Future<void> initDailyAttemptsForCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    await initDailyAttempts(userId);
  }

  /// 現在のユーザーで広告視聴を完了（便利メソッド）
  Future<void> recordAdViewAndGrantForCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    await recordAdViewAndGrant(userId);
  }

  /// 現在のユーザーでガチャ試行回数を消費（便利メソッド）
  Future<bool> consumeForCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return await consume(userId);
  }
}


