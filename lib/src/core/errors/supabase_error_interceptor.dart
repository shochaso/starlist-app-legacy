import 'package:flutter/material.dart';
import 'auth_error_handler.dart';

/// Supabaseエラーインターセプター
/// 
/// Supabaseクライアントのエラーを自動的にキャッチし、
/// 401/403エラーを適切に処理する
class SupabaseErrorInterceptor {
  /// エラーを処理し、必要に応じて認証エラーハンドラーを呼び出す
  /// 
  /// 使用例:
  /// ```dart
  /// try {
  ///   await supabase.from('table').select();
  /// } catch (e) {
  ///   await SupabaseErrorInterceptor.handleError(context, e);
  /// }
  /// ```
  static Future<T?> handleError<T>(
    BuildContext? context,
    dynamic error, {
    VoidCallback? onReauthRequired,
  }) async {
    // 認証エラーの場合は処理
    if (context != null && await AuthErrorHandler.handleAuthError(
      context,
      error,
      onReauthRequired: onReauthRequired,
    )) {
      return null;
    }

    // その他のエラーは再スロー
    if (error is Exception) {
      throw error;
    }
    throw Exception(error.toString());
  }

  /// Futureをラップしてエラーハンドリングを自動化
  /// 
  /// 使用例:
  /// ```dart
  /// final result = await SupabaseErrorInterceptor.wrap(
  ///   context,
  ///   supabase.from('table').select(),
  /// );
  /// ```
  static Future<T?> wrap<T>(
    BuildContext? context,
    Future<T> future, {
    VoidCallback? onReauthRequired,
  }) async {
    try {
      return await future;
    } catch (e) {
      return await handleError<T>(context, e, onReauthRequired: onReauthRequired);
    }
  }
}

/// BuildContext拡張（エラーハンドリング用）
extension BuildContextErrorHandling on BuildContext {
  /// Supabaseエラーを処理
  Future<T?> handleSupabaseError<T>(
    dynamic error, {
    VoidCallback? onReauthRequired,
  }) async {
    return await SupabaseErrorInterceptor.handleError<T>(
      this,
      error,
      onReauthRequired: onReauthRequired,
    );
  }

  /// Futureをラップしてエラーハンドリング
  Future<T?> wrapSupabaseCall<T>(
    Future<T> future, {
    VoidCallback? onReauthRequired,
  }) async {
    return await SupabaseErrorInterceptor.wrap<T>(
      this,
      future,
      onReauthRequired: onReauthRequired,
    );
  }
}

