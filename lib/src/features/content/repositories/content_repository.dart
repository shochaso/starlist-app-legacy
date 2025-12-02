import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/content_consumption_model.dart';
import '../models/content_model.dart';

class ContentRepository {
  final SupabaseClient _client;
  final String _contentsTable = 'contents';
  final String _consumptionsTable = 'content_consumptions';
  
  ContentRepository(this._client);
  
  /// コンテンツ一覧取得
  Future<List<ContentModel>> getContents({
    String? authorId,
    ContentTypeModel? type,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from(_contentsTable)
          .select('*, users:author_id(username, display_name, profile_image_url)')
          .eq('is_published', true);
      
      if (authorId != null) {
        query = query.eq('author_id', authorId);
      }
      
      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }
      
      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(data)
          .map((item) {
            final userData = item['users'] as Map<String, dynamic>;
            return ContentModel(
              id: item['id'] as String,
              title: item['title'] as String,
              description: item['description'] as String? ?? '',
              type: _contentTypeFromString(item['type'] as String),
              url: item['url'] as String? ?? '',
              authorId: item['author_id'] as String,
              authorName: userData['display_name'] as String? ?? userData['username'] as String,
              createdAt: DateTime.parse(item['created_at'] as String),
              updatedAt: DateTime.parse(item['updated_at'] as String),
              metadata: item['metadata'] as Map<String, dynamic>? ?? {},
              isPublished: item['is_published'] as bool? ?? true,
              likes: item['likes'] as int? ?? 0,
              comments: item['comments'] as int? ?? 0,
              shares: item['shares'] as int? ?? 0,
            );
          })
          .toList();
    } catch (e) {
      log('コンテンツ一覧の取得に失敗しました: $e');
      return [];
    }
  }
  
  /// 特定のコンテンツ取得
  Future<ContentModel?> getContentById(String id) async {
    try {
      final data = await _client
          .from(_contentsTable)
          .select('*, users:author_id(username, display_name, profile_image_url)')
          .eq('id', id)
          .single();
      
      final userData = data['users'] as Map<String, dynamic>;
      return ContentModel(
        id: data['id'] as String,
        title: data['title'] as String,
        description: data['description'] as String? ?? '',
        type: _contentTypeFromString(data['type'] as String),
        url: data['url'] as String? ?? '',
        authorId: data['author_id'] as String,
        authorName: userData['display_name'] as String? ?? userData['username'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        updatedAt: DateTime.parse(data['updated_at'] as String),
        metadata: data['metadata'] as Map<String, dynamic>? ?? {},
        isPublished: data['is_published'] as bool? ?? true,
        likes: data['likes'] as int? ?? 0,
        comments: data['comments'] as int? ?? 0,
        shares: data['shares'] as int? ?? 0,
      );
    } catch (e) {
      log('コンテンツの取得に失敗しました: $e');
      return null;
    }
  }
  
  /// コンテンツ作成
  Future<ContentModel?> createContent(ContentModel content) async {
    try {
      final newId = const Uuid().v4();
      final now = DateTime.now();
      
      final newContent = {
        'id': newId,
        'title': content.title,
        'description': content.description,
        'type': content.type.toString().split('.').last,
        'url': content.url,
        'author_id': content.authorId,
        'metadata': content.metadata,
        'is_published': content.isPublished,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      
      await _client
          .from(_contentsTable)
          .insert(newContent);
      
      final userData = await _client
          .from('profiles')
          .select('username, full_name')
          .eq('id', content.authorId)
          .single();
      
      return ContentModel(
        id: newId,
        title: content.title,
        description: content.description,
        type: content.type,
        url: content.url,
        authorId: content.authorId,
        authorName: userData['full_name'] as String? ?? userData['username'] as String,
        createdAt: now,
        updatedAt: now,
        metadata: content.metadata,
        isPublished: content.isPublished,
      );
    } catch (e) {
      log('コンテンツの作成に失敗しました: $e');
      return null;
    }
  }
  
  /// コンテンツ更新
  Future<bool> updateContent(ContentModel content) async {
    try {
      final now = DateTime.now();
      
      await _client
          .from(_contentsTable)
          .update({
            'title': content.title,
            'description': content.description,
            'type': content.type.toString().split('.').last,
            'url': content.url,
            'metadata': content.metadata,
            'is_published': content.isPublished,
            'updated_at': now.toIso8601String(),
          })
          .eq('id', content.id);
      
      return true;
    } catch (e) {
      log('コンテンツの更新に失敗しました: $e');
      return false;
    }
  }
  
  /// コンテンツ削除
  Future<bool> deleteContent(String id) async {
    try {
      await _client
          .from(_contentsTable)
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      log('コンテンツの削除に失敗しました: $e');
      return false;
    }
  }
  
  /// 特定のユーザーのコンテンツ消費データを取得
  Future<List<ContentConsumptionModel>> getUserContentConsumptions({
    required String userId,
    ContentType? contentType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from(_consumptionsTable)
          .select();
      
      // フィルタを適用
      query = query.eq('user_id', userId);
      
      if (contentType != null) {
        query = query.eq('content_type', contentType.toString().split('.').last);
      }
      
      // ソートと制限を適用
      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return List<Map<String, dynamic>>.from(data)
          .map((item) => ContentConsumptionModel.fromJson(item))
          .toList();
    } catch (e) {
      log('コンテンツ消費データの取得に失敗しました: $e');
      return [];
    }
  }
  
  /// 特定のコンテンツ消費データを取得
  Future<ContentConsumptionModel?> getContentConsumptionById(String id) async {
    try {
      final data = await _client
          .from(_consumptionsTable)
          .select()
          .eq('id', id)
          .single();
      
      return ContentConsumptionModel.fromJson(data);
    } catch (e) {
      log('コンテンツ消費データの取得に失敗しました: $e');
      return null;
    }
  }
  
  /// 新しいコンテンツ消費データを作成
  Future<ContentConsumptionModel?> createContentConsumption(ContentConsumptionModel contentConsumption) async {
    try {
      final newId = const Uuid().v4();
      final now = DateTime.now();
      
      final newConsumption = contentConsumption.toJson();
      newConsumption['id'] = newId;
      newConsumption['created_at'] = now.toIso8601String();
      newConsumption['updated_at'] = now.toIso8601String();
      
      await _client
          .from(_consumptionsTable)
          .insert(newConsumption);
      
      return ContentConsumptionModel(
        id: newId,
        userId: contentConsumption.userId,
        contentType: contentConsumption.contentType,
        contentId: contentConsumption.contentId,
        title: contentConsumption.title,
        description: contentConsumption.description,
        platform: contentConsumption.platform,
        url: contentConsumption.url,
        consumptionDate: contentConsumption.consumptionDate,
        duration: contentConsumption.duration,
        rating: contentConsumption.rating,
        comment: contentConsumption.comment,
        metadata: contentConsumption.metadata,
        isPublic: contentConsumption.isPublic,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      log('コンテンツ消費データの作成に失敗しました: $e');
      return null;
    }
  }
  
  /// コンテンツ消費データの更新
  Future<bool> updateContentConsumption(ContentConsumptionModel contentConsumption) async {
    try {
      final now = DateTime.now();
      
      final updatedConsumption = contentConsumption.toJson();
      updatedConsumption['updated_at'] = now.toIso8601String();
      
      await _client
          .from(_consumptionsTable)
          .update(updatedConsumption)
          .eq('id', contentConsumption.id);
      
      return true;
    } catch (e) {
      log('コンテンツ消費データの更新に失敗しました: $e');
      return false;
    }
  }
  
  /// コンテンツ消費データの削除
  Future<bool> deleteContentConsumption(String id) async {
    try {
      await _client
          .from(_consumptionsTable)
          .delete()
          .eq('id', id);
      
      return true;
    } catch (e) {
      log('コンテンツ消費データの削除に失敗しました: $e');
      return false;
    }
  }
  
  static ContentTypeModel _contentTypeFromString(String type) {
    try {
      return ContentTypeModel.values.firstWhere(
        (e) => e.toString().split('.').last == type,
      );
    } catch (_) {
      return ContentTypeModel.text;
    }
  }
} 