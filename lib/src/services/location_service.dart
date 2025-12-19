import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/content/models/content_consumption_model.dart';

/// 位置情報サービスクラス
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  
  LocationService._internal();
  
  /// ユーザーの現在位置を取得
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    
    try {
      // 位置情報サービスが有効かチェック
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('位置情報サービスが無効です');
        return null;
      }
      
      // 位置情報の権限をチェック
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('位置情報の権限が拒否されました');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('位置情報の権限が永続的に拒否されました');
        return null;
      }
      
      // 現在位置を取得
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('現在位置の取得に失敗しました: $e');
      return null;
    }
  }
  
  /// 座標から住所を取得（プライバシー配慮のため無効化）
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    // プライバシー保護のため、詳細な住所取得は無効化
    debugPrint('住所取得機能はプライバシー保護のため無効化されています');
    return null;
    
    /* 元の実装（プライバシーリスクのため無効化）
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      }
      
      return null;
    } catch (e) {
      debugPrint('住所の取得に失敗しました: $e');
      return null;
    }
    */
  }
  
  /// 住所から座標を取得
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return LatLng(location.latitude, location.longitude);
      }
      
      return null;
    } catch (e) {
      debugPrint('座標の取得に失敗しました: $e');
      return null;
    }
  }
  
  /// 2点間の距離を計算（メートル単位）
  double calculateDistance(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
  
  /// GeoLocationモデルを作成（プライバシー配慮版）
  Future<GeoLocation?> createGeoLocation({
    required double latitude,
    required double longitude,
    String? placeName,
    String? category,
  }) async {
    try {
      // 住所取得は無効化、店名・施設名のみ許可
      return GeoLocation(
        latitude: latitude,
        longitude: longitude,
        placeName: placeName ?? '不明な場所',
        category: category,
      );
    } catch (e) {
      debugPrint('位置情報の作成に失敗しました: $e');
      return null;
    }
  }
  
  /// GoogleMapウィジェット用のマーカーを作成
  Marker createMarker({
    required LatLng position,
    required String markerId,
    String? title,
    String? snippet,
    BitmapDescriptor icon = BitmapDescriptor.defaultMarker,
    VoidCallback? onTap,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon,
      onTap: onTap,
    );
  }
  
  /// GeoLocationモデルからMarkerを作成
  Marker? createMarkerFromGeoLocation({
    required GeoLocation location,
    required String markerId,
    BitmapDescriptor icon = BitmapDescriptor.defaultMarker,
    VoidCallback? onTap,
  }) {
    try {
      return createMarker(
        position: LatLng(location.latitude, location.longitude),
        markerId: markerId,
        title: location.placeName,
        snippet: location.displayText, // 住所の代わりに安全な表示テキストを使用
        icon: icon,
        onTap: onTap,
      );
    } catch (e) {
      debugPrint('マーカーの作成に失敗しました: $e');
      return null;
    }
  }
  
  /// 現在位置を中心としたカメラ位置を取得
  Future<CameraPosition?> getCurrentCameraPosition({double zoom = 14.0}) async {
    final position = await getCurrentPosition();
    if (position == null) return null;
    
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: zoom,
    );
  }
  
  /// 指定した位置を中心としたカメラ位置を取得
  CameraPosition getCameraPosition({
    required double latitude,
    required double longitude,
    double zoom = 14.0,
  }) {
    return CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: zoom,
    );
  }
  
  /// GeoLocationモデルからカメラ位置を取得
  CameraPosition getCameraPositionFromGeoLocation({
    required GeoLocation location,
    double zoom = 14.0,
  }) {
    return CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: zoom,
    );
  }
} 
