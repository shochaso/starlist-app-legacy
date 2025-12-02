import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/content/models/content_consumption_model.dart';
import '../features/auth/models/user_model.dart';

/// 検索サービスクラス
class SearchService {
  final SupabaseClient _client;
  
  SearchService(this._client);
  
  /// コンテンツの全文検索
  /// 
  /// [query] 検索クエリ
  /// [category] 検索するコンテンツのカテゴリ（任意）
  /// [limit] 取得する最大件数
  /// [offset] 取得開始位置
  Future<List<ContentConsumption>> searchContents({
    required String query,
    ContentCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      // 全文検索用のクエリを構築
      // Supabaseの全文検索ではwebsearchとto_tsvector/to_tsqueryを使用
      var searchQuery = _client
          .from('content_consumption')
          .select()
          .textSearch(
            'search_vector', // この列は事前にテーブルに作成しておく必要がある
            query.trim(),
            config: 'japanese', // 日本語対応の設定
            type: TextSearchType.websearch, // Web検索タイプ（AND/ORなどの演算子をサポート）
          );
      
      // カテゴリフィルタが指定されている場合は追加
      if (category != null) {
        searchQuery = searchQuery.eq('category', category.name);
      }
      
      // 公開設定が「公開」のもののみ取得
      searchQuery = searchQuery.eq('privacy_level', PrivacyLevel.public.name);
      
      // ソートと制限を適用
      final data = await searchQuery
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      if (data.isEmpty) {
        return [];
      }
      
      return List<Map<String, dynamic>>.from(data)
          .map((item) => ContentConsumption.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('コンテンツの検索に失敗しました: $e');
      return [];
    }
  }
  
  /// ユーザーの検索
  /// 
  /// [query] 検索クエリ（ユーザー名、表示名で検索）
  /// [limit] 取得する最大件数
  /// [offset] 取得開始位置
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      // ユーザー名または表示名に検索クエリが含まれるユーザーを検索
      final data = await _client
          .from('profiles')
          .select()
          .or('username.ilike.%${query.trim()}%,full_name.ilike.%${query.trim()}%')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      if (data.isEmpty) {
        return [];
      }
      
      return List<Map<String, dynamic>>.from(data)
          .map((item) => UserModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('ユーザーの検索に失敗しました: $e');
      return [];
    }
  }
  
  /// スター（影響力の高いユーザー）を検索
  /// 
  /// [limit] 取得する最大件数
  /// [offset] 取得開始位置
  Future<List<UserModel>> searchStarCreators({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('role', 'star')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      if (data.isEmpty) {
        return [];
      }
      
      return List<Map<String, dynamic>>.from(data)
          .map((item) => UserModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('スターの検索に失敗しました: $e');
      return [];
    }
  }
  
  /// 人気のタグを取得
  /// 
  /// [limit] 取得する最大件数
  Future<List<String>> getPopularTags({int limit = 10}) async {
    try {
      // タグの使用頻度を集計して上位のタグを取得する
      final data = await _client
          .rpc('get_popular_tags', params: {'tag_limit': limit});
      
      if (data == null || data.isEmpty) {
        return [];
      }
      
      return List<Map<String, dynamic>>.from(data)
          .map((item) => item['tag'] as String)
          .toList();
    } catch (e) {
      debugPrint('人気のタグの取得に失敗しました: $e');
      return [];
    }
  }
  
  /// 検索履歴を保存
  /// 
  /// [userId] ユーザーID
  /// [query] 検索クエリ
  /// [searchType] 検索タイプ（'content', 'user'など）
  Future<void> saveSearchHistory({
    required String userId,
    required String query,
    required String searchType,
  }) async {
    if (query.trim().isEmpty) {
      return;
    }
    
    try {
      await _client
          .from('search_history')
          .insert({
            'user_id': userId,
            'query': query.trim(),
            'search_type': searchType,
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      debugPrint('検索履歴の保存に失敗しました: $e');
    }
  }
  
  /// ユーザーの検索履歴を取得
  /// 
  /// [userId] ユーザーID
  /// [limit] 取得する最大件数
  Future<List<String>> getUserSearchHistory({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final data = await _client
          .from('search_history')
          .select('query')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      if (data.isEmpty) {
        return [];
      }
      
      // 重複を排除
      final uniqueQueries = <String>{};
      for (final item in data) {
        uniqueQueries.add(item['query'] as String);
      }
      
      return uniqueQueries.toList();
    } catch (e) {
      debugPrint('検索履歴の取得に失敗しました: $e');
      return [];
    }
  }
  
  /// ユーザーの検索履歴をクリア
  /// 
  /// [userId] ユーザーID
  Future<void> clearUserSearchHistory(String userId) async {
    try {
      await _client
          .from('search_history')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('検索履歴のクリアに失敗しました: $e');
    }
  }
} 