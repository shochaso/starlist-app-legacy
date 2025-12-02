import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../models/parental_consent.dart';

/// 親権者同意サービス
class ParentalConsentService {
  static final _supabase = Supabase.instance.client;

  /// 親権者同意情報を提出
  static Future<ParentalConsentResult> submitParentalConsent(
    ParentalConsentRequest request,
  ) async {
    try {
      // 1. 同意書ファイルをアップロード
      String? documentUrl;
      if (request.consentDocument != null) {
        documentUrl = await _uploadConsentDocument(
          request.userId,
          request.consentDocument!,
        );
      }

      // 2. 親権者同意情報をデータベースに保存
      final response = await _supabase.from('parental_consents').insert({
        'user_id': request.userId,
        'parent_full_name': request.parentFullName,
        'parent_email': request.parentEmail,
        'parent_phone': request.parentPhone,
        'parent_address': request.parentAddress,
        'relationship_to_minor': request.relationshipToMinor,
        'consent_document_url': documentUrl,
        'verification_status': 'parental_consent_submitted',
      }).select().single();

      // 3. ユーザーの認証ステータスを更新
      await _supabase.from('profiles').update({
        'verification_status': 'parental_consent_submitted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', request.userId);

      // 4. 管理者審査ログを作成
      await _createAdminReviewLog(
        request.userId,
        'parental_consent_submitted',
        '親権者同意書が提出されました',
      );

      // 5. 親権者にメール通知を送信
      await _sendParentalNotificationEmail(
        request.parentEmail,
        request.parentFullName,
        response['id'],
      );

      return ParentalConsentResult(
        success: true,
        consentId: response['id'],
        message: '親権者同意情報を提出しました',
      );
    } catch (e) {
      return ParentalConsentResult(
        success: false,
        error: '親権者同意情報の提出に失敗しました: ${e.toString()}',
      );
    }
  }

  /// 親権者eKYC認証を開始
  static Future<ParentalConsentResult> startParentalEKYC(
    String consentId,
  ) async {
    try {
      // 親権者同意情報を取得
      final consent = await _supabase
          .from('parental_consents')
          .select()
          .eq('id', consentId)
          .single();

      // eKYC認証を開始（外部サービス連携）
      // 実装時は実際のeKYCサービスAPIを呼び出し
      
      // ステータスを更新
      await _supabase.from('parental_consents').update({
        'verification_status': 'parental_ekyc_required',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', consentId);

      return ParentalConsentResult(
        success: true,
        message: '親権者eKYC認証を開始しました',
      );
    } catch (e) {
      return ParentalConsentResult(
        success: false,
        error: '親権者eKYC認証の開始に失敗しました: ${e.toString()}',
      );
    }
  }

  /// 親権者同意状況を取得
  static Future<ParentalConsent?> getParentalConsent(String userId) async {
    try {
      final response = await _supabase
          .from('parental_consents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return ParentalConsent.fromJson(response);
    } catch (e) {
      print('親権者同意情報の取得エラー: $e');
      return null;
    }
  }

  /// 管理者用: 親権者同意一覧を取得
  static Future<List<ParentalConsent>> getParentalConsentsForAdmin({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('parental_consents')
          .select('''
            *,
            users!inner(id, name, email, legal_name, birth_date)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (status != null) {
        query = query.eq('verification_status', status);
      }

      final response = await query;

      return response.map((json) => ParentalConsent.fromJson(json)).toList();
    } catch (e) {
      print('親権者同意一覧の取得エラー: $e');
      return [];
    }
  }

  /// 管理者用: 親権者同意を承認
  static Future<bool> approveParentalConsent(
    String consentId,
    String adminUserId,
    String? notes,
  ) async {
    try {
      // 親権者同意情報を取得
      final consent = await _supabase
          .from('parental_consents')
          .select('user_id')
          .eq('id', consentId)
          .single();

      // 親権者同意ステータスを更新
      await _supabase.from('parental_consents').update({
        'verification_status': 'approved',
        'admin_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', consentId);

      // ユーザーの認証ステータスを更新
      await _supabase.from('profiles').update({
        'verification_status': 'parental_consent_approved',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', consent['user_id']);

      // 管理者審査ログを作成
      await _createAdminReviewLog(
        consent['user_id'],
        'parental_consent_approved',
        '親権者同意が承認されました',
        adminUserId: adminUserId,
        notes: notes,
      );

      return true;
    } catch (e) {
      print('親権者同意承認エラー: $e');
      return false;
    }
  }

  /// 管理者用: 親権者同意を拒否
  static Future<bool> rejectParentalConsent(
    String consentId,
    String adminUserId,
    String rejectionReason,
  ) async {
    try {
      // 親権者同意情報を取得
      final consent = await _supabase
          .from('parental_consents')
          .select('user_id')
          .eq('id', consentId)
          .single();

      // 親権者同意ステータスを更新
      await _supabase.from('parental_consents').update({
        'verification_status': 'rejected',
        'admin_notes': rejectionReason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', consentId);

      // ユーザーの認証ステータスを更新
      await _supabase.from('profiles').update({
        'verification_status': 'rejected',
        'verification_notes': rejectionReason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', consent['user_id']);

      // 管理者審査ログを作成
      await _createAdminReviewLog(
        consent['user_id'],
        'rejected',
        '親権者同意が拒否されました: $rejectionReason',
        adminUserId: adminUserId,
        notes: rejectionReason,
      );

      return true;
    } catch (e) {
      print('親権者同意拒否エラー: $e');
      return false;
    }
  }

  /// 同意書ファイルをアップロード
  static Future<String> _uploadConsentDocument(
    String userId,
    PlatformFile file,
  ) async {
    try {
      final fileExt = file.extension ?? 'pdf';
      final fileName = 'consent_document_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'parental_consents/$fileName';

      // Supabase Storageにアップロード
      final response = await _supabase.storage
          .from('documents')
          .uploadBinary(
            filePath,
            file.bytes!,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExt),
            ),
          );

      // 公開URLを取得
      final publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('ファイルのアップロードに失敗しました: $e');
    }
  }

  /// ファイルのContent-Typeを取得
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// 管理者審査ログを作成
  static Future<void> _createAdminReviewLog(
    String userId,
    String newStatus,
    String notes, {
    String? adminUserId,
  }) async {
    try {
      await _supabase.from('admin_review_logs').insert({
        'user_id': userId,
        'admin_user_id': adminUserId,
        'review_type': 'parental_consent_review',
        'new_status': newStatus,
        'decision': newStatus.contains('approved') ? 'approved' : 
                    newStatus.contains('rejected') ? 'rejected' : 'in_progress',
        'review_notes': notes,
      });
    } catch (e) {
      print('管理者審査ログの作成エラー: $e');
    }
  }

  /// 親権者にメール通知を送信
  static Future<void> _sendParentalNotificationEmail(
    String parentEmail,
    String parentName,
    String consentId,
  ) async {
    try {
      // 実際の実装では、メール送信サービス（SendGrid、Amazon SESなど）を使用
      // ここではログ出力のみ
      print('親権者通知メール送信: $parentEmail');
      
      // メール送信のためのSupabase Edge Functionを呼び出し
      await _supabase.functions.invoke('send-parental-notification', body: {
        'parentEmail': parentEmail,
        'parentName': parentName,
        'consentId': consentId,
      });
    } catch (e) {
      print('親権者メール通知送信エラー: $e');
      // メール送信失敗はログのみで、処理は継続
    }
  }
}

/// 親権者同意結果
class ParentalConsentResult {
  final bool success;
  final String? consentId;
  final String? message;
  final String? error;

  ParentalConsentResult({
    required this.success,
    this.consentId,
    this.message,
    this.error,
  });
} 