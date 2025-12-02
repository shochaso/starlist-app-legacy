import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/agency_terms_agreement.dart';

/// 事務所規約同意サービス
class TermsAgreementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 規約同意を送信
  Future<AgencyTermsAgreementResult> submitAgreement(
    AgencyTermsAgreement agreement,
  ) async {
    try {
      // 既存の同意記録があるかチェック
      final existingAgreement = await getUserAgreement(agreement.userId);
      if (existingAgreement != null) {
        return const AgencyTermsAgreementResult.failure(
          error: '既に規約同意が完了しています',
        );
      }

      // データベースに保存
      final response = await _supabase
          .from('agency_terms_agreements')
          .insert(agreement.toJson())
          .select()
          .single();

      final savedAgreement = AgencyTermsAgreement.fromJson(response);

      // ユーザーの認証ステータスを更新
      await _supabase
          .from('profiles')
          .update({
            'verification_status_final': 'awaiting_ekyc',
            'agency_terms_agreed': true,
            'agency_terms_agreed_at': DateTime.now().toIso8601String(),
            'agency_name': agreement.agencyName,
            'agency_contact_info': agreement.agencyContactEmail,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', agreement.userId);

      // 認証進捗を更新
      await _updateVerificationProgress(agreement.userId, true);

      return AgencyTermsAgreementResult.success(
        agreementId: savedAgreement.id!,
        message: '事務所利用規約への同意が完了しました',
      );
    } catch (e) {
      return AgencyTermsAgreementResult.failure(
        error: '規約同意の送信に失敗しました: ${e.toString()}',
      );
    }
  }

  /// ユーザーの規約同意状況を取得
  Future<AgencyTermsAgreement?> getUserAgreement(String userId) async {
    try {
      final response = await _supabase
          .from('agency_terms_agreements')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AgencyTermsAgreement.fromJson(response);
    } catch (e) {
      throw Exception('規約同意データの取得に失敗しました: ${e.toString()}');
    }
  }

  /// 認証進捗を更新
  Future<void> _updateVerificationProgress(String userId, bool termsAgreed) async {
    try {
      // 既存の進捗レコードを取得
      final existingProgress = await _supabase
          .from('verification_progress')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingProgress != null) {
        // 既存レコードを更新
        await _supabase
            .from('verification_progress')
            .update({
              'terms_agreement_completed': termsAgreed,
              'terms_agreement_completed_at': termsAgreed ? DateTime.now().toIso8601String() : null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // 新規レコードを作成
        await _supabase
            .from('verification_progress')
            .insert({
              'user_id': userId,
              'terms_agreement_completed': termsAgreed,
              'terms_agreement_completed_at': termsAgreed ? DateTime.now().toIso8601String() : null,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      throw Exception('認証進捗の更新に失敗しました: ${e.toString()}');
    }
  }

  /// 管理者用：全規約同意一覧を取得
  Future<List<AgencyTermsAgreement>> getAllAgreements() async {
    try {
      final response = await _supabase
          .from('agency_terms_agreements')
          .select()
          .order('created_at', ascending: false);

      return response
          .map((json) => AgencyTermsAgreement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('規約同意一覧の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 管理者用：特定期間の規約同意を取得
  Future<List<AgencyTermsAgreement>> getAgreementsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('agency_terms_agreements')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return response
          .map((json) => AgencyTermsAgreement.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('期間指定での規約同意取得に失敗しました: ${e.toString()}');
    }
  }
} 