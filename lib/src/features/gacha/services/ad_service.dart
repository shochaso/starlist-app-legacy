import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gacha_limits_models.dart';
import '../../../core/device/device_id.dart';

/// 広告サービスの抽象クラス
abstract class AdService {
  /// 広告を読み込み
  Future<void> loadAd(AdType adType);

  /// 広告を表示
  Future<AdViewResult> showAd(AdType adType);

  /// 広告が利用可能かどうか
  Future<bool> isAdAvailable(AdType adType);

  /// 広告を破棄
  Future<void> dispose();
}

/// 広告視聴の結果
class AdViewResult {
  final bool success;
  final int rewardedAttempts;
  final String? errorMessage;

  AdViewResult({
    required this.success,
    this.rewardedAttempts = 0,
    this.errorMessage,
  });
}

/// モック広告サービス（実際の広告SDKがない場合の代替）
class MockAdService implements AdService {
  final SupabaseClient _supabaseService;
  Timer? _adTimer;

  MockAdService(this._supabaseService);

  @override
  Future<void> loadAd(AdType adType) async {
    // モックなので何もしない
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<AdViewResult> showAd(AdType adType) async {
    try {
      final userId = _supabaseService.auth.currentUser?.id;
      if (userId == null) {
        return AdViewResult(success: false, errorMessage: 'not_logged_in');
      }

      final adViewId = await _recordAdViewInitiated(adType);

      // モック視聴: 3秒待って成功扱い
      final completer = Completer<AdViewResult>();
      _adTimer?.cancel();
      _adTimer = Timer(const Duration(seconds: 3), () async {
        try {
          final deviceId = await DeviceId.get();
          final granted = await _completeAndGrant(userId, adViewId, deviceId);
          completer.complete(granted);
        } catch (e) {
          completer.complete(AdViewResult(success: false, errorMessage: e.toString()));
        }
      });

      return completer.future;
    } catch (e) {
      return AdViewResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<bool> isAdAvailable(AdType adType) async {
    // モックなので常に利用可能
    return true;
  }

  @override
  Future<void> dispose() async {
    _adTimer?.cancel();
    _adTimer = null;
  }

  /// 広告視聴開始を記録し ad_view_id を返す
  Future<String> _recordAdViewInitiated(AdType adType) async {
    final userId = _supabaseService.auth.currentUser?.id;
    if (userId == null) throw Exception('not_logged_in');

    final deviceId = await DeviceId.get();
    final data = await _supabaseService.from('ad_views').insert({
      'user_id': userId,
      'ad_type': adType.name,
      'ad_provider': 'mock_provider',
      'ad_id': 'mock_ad_${DateTime.now().millisecondsSinceEpoch}',
      'view_duration': 0,
      'completed': false,
      'reward_attempts': 1,
      'viewed_at': DateTime.now().toIso8601String(),
      'device_id': deviceId,
      'status': 'initiated',
      'date_key': null,
    }).select('id').single();

    return data['id'] as String;
  }

  Future<AdViewResult> _completeAndGrant(String userId, String adViewId, String deviceId) async {
    try {
      // 新しいスキーマでは、complete_ad_view_and_grant_ticketは
      // target_user_idのみを受け取る（広告ログは自動で作成される）
      await _supabaseService.rpc('complete_ad_view_and_grant_ticket', params: {
        'target_user_id': userId,
      });

      // 成功時はvoidを返すため、例外がなければ成功
      return AdViewResult(success: true, rewardedAttempts: 1);
    } catch (e) {
      return AdViewResult(success: false, errorMessage: e.toString());
    }
  }
}

/// 実際の広告サービス（Google AdMobなどを使用する場合）
// class GoogleAdMobService implements AdService {
//   // Google AdMobの実装
//   // RewardedAd, InterstitialAd などの実装
// }

/// AdService のプロバイダー
final adServiceProvider = Provider<AdService>((ref) {
  final supabase = Supabase.instance.client;
  return MockAdService(supabase);
});
