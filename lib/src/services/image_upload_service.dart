import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

/// 画像アップロードサービス
class ImageUploadService {
  final SupabaseClient _supabaseClient;
  static const String _bucketName = 'profile-images';
  static const int _maxImageSize = 2 * 1024 * 1024; // 2MB
  static const int _maxWidth = 1024;
  static const int _maxHeight = 1024;
  static const int _compressionQuality = 85;

  ImageUploadService(this._supabaseClient);

  /// プロフィール画像をアップロード
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // 画像の圧縮・最適化
      final optimizedImage = await _optimizeImage(imageFile);
      
      // ファイル名を生成（ユーザーIDベース）
      final fileName = _generateFileName(userId, 'profile');
      
      // Supabase Storageにアップロード
      final filePath = await _uploadToSupabaseStorage(
        fileName: fileName,
        imageBytes: optimizedImage,
        contentType: 'image/jpeg',
      );
      
      // 公開URLを取得
      final publicUrl = _supabaseClient.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw ImageUploadException('プロフィール画像のアップロードに失敗しました: ${e.toString()}');
    }
  }

  /// コンテンツ画像をアップロード（複数画像対応）
  Future<List<String>> uploadContentImages({
    required String userId,
    required List<File> imageFiles,
    String? contentId,
  }) async {
    try {
      final uploadedUrls = <String>[];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final imageFile = imageFiles[i];
        
        // 画像の圧縮・最適化
        final optimizedImage = await _optimizeImage(imageFile);
        
        // ファイル名を生成
        final fileName = _generateFileName(
          userId, 
          'content',
          index: i,
          contentId: contentId,
        );
        
        // Supabase Storageにアップロード
        final filePath = await _uploadToSupabaseStorage(
          fileName: fileName,
          imageBytes: optimizedImage,
          contentType: 'image/jpeg',
        );
        
        // 公開URLを取得
        final publicUrl = _supabaseClient.storage
            .from(_bucketName)
            .getPublicUrl(filePath);
        
        uploadedUrls.add(publicUrl);
      }
      
      return uploadedUrls;
    } catch (e) {
      throw ImageUploadException('コンテンツ画像のアップロードに失敗しました: ${e.toString()}');
    }
  }

  /// 画像を削除
  Future<void> deleteImage(String imageUrl) async {
    try {
      // URLからファイルパスを抽出
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;
      
      // Supabase Storageから削除
      await _supabaseClient.storage
          .from(_bucketName)
          .remove([fileName]);
    } catch (e) {
      throw ImageUploadException('画像の削除に失敗しました: ${e.toString()}');
    }
  }

  /// 古いプロフィール画像を削除
  Future<void> deleteOldProfileImage({
    required String userId,
    required String? oldImageUrl,
  }) async {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;
    
    try {
      // デフォルト画像の場合はスキップ
      if (oldImageUrl.contains('default_profile')) return;
      
      await deleteImage(oldImageUrl);
    } catch (e) {
      // 古い画像の削除に失敗してもエラーにしない（ログは出力）
      if (kDebugMode) {
        print('Warning: Failed to delete old profile image: $e');
      }
    }
  }

  /// 画像の最適化
  Future<Uint8List> _optimizeImage(File imageFile) async {
    try {
      // ファイルサイズチェック
      final fileSize = await imageFile.length();
      if (fileSize > _maxImageSize) {
        throw const ImageUploadException('画像サイズが大きすぎます（上限: ${_maxImageSize ~/ (1024 * 1024)}MB）');
      }

      // 画像をデコード
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw const ImageUploadException('画像の読み込みに失敗しました');
      }

      // 画像をリサイズ（アスペクト比を保持）
      img.Image resized = image;
      if (image.width > _maxWidth || image.height > _maxHeight) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? _maxWidth : null,
          height: image.height > image.width ? _maxHeight : null,
        );
      }

      // JPEGエンコード（圧縮）
      final compressedBytes = img.encodeJpg(resized, quality: _compressionQuality);
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      throw ImageUploadException('画像の最適化に失敗しました: ${e.toString()}');
    }
  }

  /// Supabase Storageにアップロード
  Future<String> _uploadToSupabaseStorage({
    required String fileName,
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    try {
      await _supabaseClient.storage
          .from(_bucketName)
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true, // 同じファイル名の場合は上書き
            ),
          );
      
      return fileName;
    } catch (e) {
      throw ImageUploadException('ストレージへのアップロードに失敗しました: ${e.toString()}');
    }
  }

  /// ファイル名を生成
  String _generateFileName(
    String userId,
    String type, {
    int? index,
    String? contentId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const extension = 'jpg';
    
    switch (type) {
      case 'profile':
        return 'profiles/$userId/profile_$timestamp.$extension';
      case 'content':
        final contentPrefix = contentId ?? 'content_$timestamp';
        final indexSuffix = index != null ? '_$index' : '';
        return 'content/$userId/$contentPrefix$indexSuffix.$extension';
      default:
        return 'misc/$userId/${type}_$timestamp.$extension';
    }
  }

  /// ストレージバケットの初期化
  static Future<void> initializeBucket(SupabaseClient client) async {
    try {
      // バケットが存在するかチェック
      final buckets = await client.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == _bucketName);
      
      if (!bucketExists) {
        // バケットを作成（パブリックアクセス有効）
        await client.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public: true,
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            fileSizeLimit: _maxImageSize,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Failed to initialize storage bucket: $e');
      }
    }
  }

  /// 画像URLの検証
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    // Supabaseのストレージドメインかチェック
    return url.contains('supabase') || url.startsWith('http');
  }

  /// ファイルサイズを人間が読める形式に変換
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 画像アップロードのカスタム例外
class ImageUploadException implements Exception {
  final String message;
  
  const ImageUploadException(this.message);
  
  @override
  String toString() => 'ImageUploadException: $message';
}

/// アップロード進捗情報
class UploadProgress {
  final String fileName;
  final int bytesUploaded;
  final int totalBytes;
  final double percentage;
  final bool isCompleted;
  final String? error;

  const UploadProgress({
    required this.fileName,
    required this.bytesUploaded,
    required this.totalBytes,
    required this.percentage,
    this.isCompleted = false,
    this.error,
  });

  factory UploadProgress.start(String fileName, int totalBytes) {
    return UploadProgress(
      fileName: fileName,
      bytesUploaded: 0,
      totalBytes: totalBytes,
      percentage: 0.0,
    );
  }

  factory UploadProgress.update(String fileName, int bytesUploaded, int totalBytes) {
    final percentage = totalBytes > 0 ? (bytesUploaded / totalBytes) * 100 : 0.0;
    return UploadProgress(
      fileName: fileName,
      bytesUploaded: bytesUploaded,
      totalBytes: totalBytes,
      percentage: percentage,
    );
  }

  factory UploadProgress.completed(String fileName, int totalBytes) {
    return UploadProgress(
      fileName: fileName,
      bytesUploaded: totalBytes,
      totalBytes: totalBytes,
      percentage: 100.0,
      isCompleted: true,
    );
  }

  factory UploadProgress.error(String fileName, String error) {
    return UploadProgress(
      fileName: fileName,
      bytesUploaded: 0,
      totalBytes: 0,
      percentage: 0.0,
      error: error,
    );
  }
}
