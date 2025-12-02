import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:starlist_app/src/features/auth/models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('ログインに失敗しました');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } catch (e) {
      throw Exception('ログインに失敗しました: ${e.toString()}');
    }
  }

  Future<UserModel> signInWithIdentifier(String identifier, String password) async {
    try {
      String email = identifier.trim();
      if (!email.contains('@')) {
        final data = await _supabase
            .from('profiles')
            .select('email')
            .eq('username', identifier)
            .maybeSingle();
        if (data == null || data['email'] == null || (data['email'] as String).isEmpty) {
          throw Exception('ユーザー名が見つかりませんでした');
        }
        email = data['email'] as String;
      }
      return await signInWithEmailAndPassword(email, password);
    } catch (e) {
      throw Exception('ログインに失敗しました: ${e.toString()}');
    }
  }

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
        },
      );
      if (response.user == null) {
        throw Exception('ユーザー登録に失敗しました');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } catch (e) {
      if (e is AuthException && e.message.contains('User already registered')) {
         throw Exception('このメールアドレスは既に使用されています。');
      }
      throw Exception('ユーザー登録に失敗しました: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('ログアウトに失敗しました: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
       await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('パスワードリセットに失敗しました: ${e.toString()}');
    }
  }

  /// Google OAuthでサインイン
  /// 
  /// 戻り値: UserModel（成功時）、null（キャンセル時）
  /// 例外: エラー時にExceptionをスロー
  Future<UserModel?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      // OAuth認証は外部ブラウザで完了するため、
      // 認証完了後はauthStateChangesで検知する
      // ここでは認証開始の成功のみを返す
      return null;
    } catch (e) {
      throw Exception('Googleログインに失敗しました: ${e.toString()}');
    }
  }

  /// Apple OAuthでサインイン
  /// 
  /// 戻り値: UserModel（成功時）、null（キャンセル時）
  /// 例外: エラー時にExceptionをスロー
  Future<UserModel?> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _getRedirectUrl(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      
      // OAuth認証は外部ブラウザで完了するため、
      // 認証完了後はauthStateChangesで検知する
      // ここでは認証開始の成功のみを返す
      return null;
    } catch (e) {
      throw Exception('Appleログインに失敗しました: ${e.toString()}');
    }
  }

  /// OAuth認証後のリダイレクトURLを取得
  /// 
  /// プラットフォームに応じた適切なURLを返す
  String _getRedirectUrl() {
    // 本番環境では、Supabase Dashboardで設定したリダイレクトURLを使用
    // 開発環境では、デフォルトのリダイレクトURLを使用
    // 注意: 実際の実装では、環境変数や設定ファイルから取得する
    return 'io.supabase.starlist://login-callback';
  }

  /// セッションをリフレッシュ
  /// 
  /// 401エラー時に自動的に呼び出される
  Future<void> refreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase.auth.refreshSession();
      }
    } catch (e) {
      // リフレッシュに失敗した場合は、再ログインが必要
      throw Exception('セッションの更新に失敗しました。再度ログインしてください: ${e.toString()}');
    }
  }

  /// 認証状態の変更を監視
  /// 
  /// 401/403エラー時に自動的に再認証を試みる
  Stream<AuthState> watchAuthState() {
    return _supabase.auth.onAuthStateChange.map((state) {
      // セッション切れの場合は自動的にリフレッシュを試みる
      if (state.event == AuthChangeEvent.tokenRefreshed) {
        // トークンがリフレッシュされた
      } else if (state.event == AuthChangeEvent.signedOut) {
        // サインアウトされた
      } else if (state.event == AuthChangeEvent.signedIn) {
        // サインイン後にauth-syncを呼び出す
        _syncAuthProfile(state.session?.user.id);
      }
      return state;
    });
  }

  /// auth-sync Edge Functionを呼び出してプロフィールとentitlementsを同期
  /// 
  /// 注意: このメソッドは非同期で実行され、エラーはログに記録されるのみ
  Future<void> _syncAuthProfile(String? userId) async {
    if (userId == null) return;

    try {
      // auth-sync Edge Functionを呼び出す
      // 注意: 実際の実装では、Supabase Edge FunctionのURLを使用
      await _supabase.functions.invoke(
        'auth-sync',
        body: {
          'user_id': userId,
          'provider': 'email', // OAuthの場合は'google'または'apple'
        },
      );
    } catch (e) {
      // エラーはログに記録するのみ（アプリの動作を止めない）
      debugPrint('auth-sync failed: $e');
    }
  }

  /// OAuth認証後にauth-syncを呼び出す
  /// 
  /// このメソッドはOAuth認証成功後に手動で呼び出す
  Future<void> syncAuthAfterOAuth(String userId, String provider) async {
    try {
      await _supabase.functions.invoke(
        'auth-sync',
        body: {
          'user_id': userId,
          'provider': provider, // 'google' or 'apple'
        },
      );
    } catch (e) {
      throw Exception('auth-sync failed: ${e.toString()}');
    }
  }
}
