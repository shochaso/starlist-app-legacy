import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証エラーハンドラー
/// 
/// 401/403エラーを検出し、適切な処理を行う
class AuthErrorHandler {
  /// SupabaseエラーからHTTPステータスコードを抽出
  static int? extractStatusCode(dynamic error) {
    if (error is PostgrestException) {
      // PostgrestExceptionのメッセージからステータスコードを推測
      final message = error.message.toLowerCase();
      if (message.contains('401') || message.contains('unauthorized') || message.contains('jwt')) {
        return 401;
      }
      if (message.contains('403') || message.contains('forbidden') || message.contains('permission')) {
        return 403;
      }
      // PostgrestExceptionのcodeから推測
      if (error.code == 'PGRST301' || error.code == 'PGRST302') {
        return 401;
      }
      if (error.code == 'PGRST303') {
        return 403;
      }
    }
    if (error is AuthException) {
      // AuthExceptionのメッセージからステータスコードを推測
      final message = error.message.toLowerCase();
      if (message.contains('401') || message.contains('unauthorized') || message.contains('jwt')) {
        return 401;
      }
      if (message.contains('403') || message.contains('forbidden')) {
        return 403;
      }
    }
    // エラーメッセージ全体から推測
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 401;
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 403;
    }
    return null;
  }

  /// エラーが401（認証エラー）かどうかを判定
  static bool isUnauthorizedError(dynamic error) {
    final statusCode = extractStatusCode(error);
    return statusCode == 401;
  }

  /// エラーが403（権限エラー）かどうかを判定
  static bool isForbiddenError(dynamic error) {
    final statusCode = extractStatusCode(error);
    return statusCode == 403;
  }

  /// 認証エラー（401/403）かどうかを判定
  static bool isAuthError(dynamic error) {
    return isUnauthorizedError(error) || isForbiddenError(error);
  }

  /// 認証エラーを処理し、必要に応じて再認証を促す
  /// 
  /// 戻り値: エラーが処理された場合true、処理不要の場合false
  static Future<bool> handleAuthError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onReauthRequired,
  }) async {
    if (!isAuthError(error)) {
      return false;
    }

    final statusCode = extractStatusCode(error);
    
    if (statusCode == 401) {
      // セッション切れの場合は再ログインを促す
      if (onReauthRequired != null) {
        onReauthRequired();
      } else {
        // デフォルトの処理: ログアウトしてログイン画面へ
        await _handleUnauthorized(context);
      }
      return true;
    }

    if (statusCode == 403) {
      // 権限不足の場合はエラーメッセージを表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('この操作を実行する権限がありません'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return true;
    }

    return false;
  }

  /// 401エラー時のデフォルト処理
  static Future<void> _handleUnauthorized(BuildContext context) async {
    try {
      // セッションをクリア
      await Supabase.instance.client.auth.signOut();
      
      // ログイン画面へ遷移（ナビゲーションは呼び出し側で実装）
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('セッションが切れました。再度ログインしてください'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // エラー時はログのみ
      debugPrint('AuthErrorHandler: Failed to handle unauthorized: $e');
    }
  }

  /// エラーメッセージを取得
  static String getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    if (error is Exception) {
      return error.toString();
    }
    return 'エラーが発生しました';
  }
}

