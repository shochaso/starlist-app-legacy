// Status:: in-progress
// Source-of-Truth:: lib/src/features/ops/ops_telemetry.dart
// Spec-State:: 確定済み
// Last-Updated:: 2025-11-07

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../config/environment_config.dart';

/// OPS Telemetry client for sending operational metrics to Edge Functions
class OpsTelemetry {
  final String baseUrl;
  final String app;
  final String env;
  
  // Deduplication: track recent payload hashes (5 minutes window)
  static final Map<String, int> _recentHashes = {};
  static const int _dedupeWindowMs = 5 * 60 * 1000; // 5 minutes
  
  // Retry queue for failed sends
  static final List<Map<String, dynamic>> _retryQueue = [];
  static const int _maxRetries = 3;

  OpsTelemetry({
    required this.baseUrl,
    required this.app,
    required this.env,
  });

  /// Factory constructor for production environment
  factory OpsTelemetry.prod() {
    const supabaseUrl = EnvironmentConfig.supabaseUrl;
    // Edge Functions URL format: {supabaseUrl}/functions/v1/{functionName}
    const baseUrl = '$supabaseUrl/functions/v1';
    return OpsTelemetry(
      baseUrl: baseUrl,
      app: 'starlist',
      env: 'prod',
    );
  }

  /// Factory constructor for staging environment
  factory OpsTelemetry.staging() {
    const supabaseUrl = EnvironmentConfig.supabaseUrl;
    const baseUrl = '$supabaseUrl/functions/v1';
    return OpsTelemetry(
      baseUrl: baseUrl,
      app: 'starlist',
      env: 'stg',
    );
  }

  /// Factory constructor for development environment
  factory OpsTelemetry.dev() {
    const supabaseUrl = EnvironmentConfig.supabaseUrl;
    const baseUrl = '$supabaseUrl/functions/v1';
    return OpsTelemetry(
      baseUrl: baseUrl,
      app: 'starlist',
      env: 'dev',
    );
  }

  /// Generate hash for payload deduplication
  String _generatePayloadHash(Map<String, dynamic> payload) {
    final sorted = Map.fromEntries(
      payload.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    final json = jsonEncode(sorted);
    return json.hashCode.toString();
  }

  /// Check if payload was recently sent (deduplication)
  bool _isDuplicate(String hash) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final timestamp = _recentHashes[hash];
    
    if (timestamp != null) {
      if (now - timestamp < _dedupeWindowMs) {
        return true; // Duplicate within window
      }
      _recentHashes.remove(hash); // Expired, remove
    }
    
    _recentHashes[hash] = now;
    return false;
  }

  /// Exponential backoff with jitter
  Future<void> _waitWithBackoff(int attempt) async {
    final baseDelay = pow(2, attempt).toInt() * 1000; // Exponential: 1s, 2s, 4s
    final jitter = Random().nextInt(1000); // Random 0-1s
    await Future.delayed(Duration(milliseconds: baseDelay + jitter));
  }

  /// Send telemetry event to Edge Function with retry and deduplication
  Future<bool> send({
    required String event,
    required bool ok,
    int? latencyMs,
    String? errCode,
    Map<String, dynamic>? extra,
  }) async {
    final payload = {
      'app': app,
      'env': env,
      'event': event,
      'ok': ok,
      'latency_ms': latencyMs,
      'err_code': errCode,
      'extra': extra,
    };
    
    // Deduplication check
    final hash = _generatePayloadHash(payload);
    if (_isDuplicate(hash)) {
      print('[OpsTelemetry] Duplicate payload detected, skipping: $event');
      return true; // Consider duplicate as success
    }
    
    // Retry logic with exponential backoff + jitter
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$baseUrl/telemetry');
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${EnvironmentConfig.supabaseAnonKey}',
          },
          body: jsonEncode(payload),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Request timeout'),
        );

        if (response.statusCode == 201) {
          return true;
        }
        
        // Retry on 5xx errors
        if (response.statusCode >= 500 && attempt < _maxRetries - 1) {
          await _waitWithBackoff(attempt);
          continue;
        }
        
        // Non-retryable error
        print('[OpsTelemetry] Send failed: ${response.statusCode}');
        return false;
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          await _waitWithBackoff(attempt);
          continue;
        }
        // Final attempt failed, add to retry queue
        _retryQueue.add({
          'payload': payload,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('[OpsTelemetry] Send failed after $_maxRetries attempts: $e');
        return false;
      }
    }
    
    return false;
  }
  
  /// Retry failed sends from queue
  static Future<void> retryFailed() async {
    if (_retryQueue.isEmpty) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final toRetry = _retryQueue.where((item) {
      // Retry items older than 1 minute
      return now - item['timestamp'] > 60 * 1000;
    }).toList();
    
    for (final item in toRetry) {
      _retryQueue.remove(item);
      // Note: This requires access to OpsTelemetry instance
      // In practice, you'd store the instance or recreate it
    }
  }
}




    final jitter = Random().nextInt(1000); // Random 0-1s
    await Future.delayed(Duration(milliseconds = baseDelay + jitter));
  }

  /// Send telemetry event to Edge Function with retry and deduplication
  Future<bool> send({
    required String event,
    required bool ok,
    int? latencyMs,
    String? errCode,
    Map<String, dynamic>? extra,
  }) async {
    final payload = {
      'app': app,
      'env': env,
      'event': event,
      'ok': ok,
      'latency_ms': latencyMs,
      'err_code': errCode,
      'extra': extra,
    };
    
    // Deduplication check
    final hash = _generatePayloadHash(payload);
    if (_isDuplicate(hash)) {
      print('[OpsTelemetry] Duplicate payload detected, skipping: $event');
      return true; // Consider duplicate as success
    }
    
    // Retry logic with exponential backoff + jitter
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final uri = Uri.parse('$baseUrl/telemetry');
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${EnvironmentConfig.supabaseAnonKey}',
          },
          body: jsonEncode(payload),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Request timeout'),
        );

        if (response.statusCode == 201) {
          return true;
        }
        
        // Retry on 5xx errors
        if (response.statusCode >= 500 && attempt < _maxRetries - 1) {
          await _waitWithBackoff(attempt);
          continue;
        }
        
        // Non-retryable error
        print('[OpsTelemetry] Send failed: ${response.statusCode}');
        return false;
      } catch (e) {
        if (attempt < _maxRetries - 1) {
          await _waitWithBackoff(attempt);
          continue;
        }
        // Final attempt failed, add to retry queue
        _retryQueue.add({
          'payload': payload,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        print('[OpsTelemetry] Send failed after $_maxRetries attempts: $e');
        return false;
      }
    }
    
    return false;
  }
  
  /// Retry failed sends from queue
  Future<void> retryFailed() async {
    if (_retryQueue.isEmpty) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final toRetry = _retryQueue.where((item) {
      // Retry items older than 1 minute
      return now - item['timestamp'] > 60 * 1000;
    }).toList();
    
    for (final item in toRetry) {
      _retryQueue.remove(item);
      // Note: This requires access to OpsTelemetry instance
      // In practice, you'd store the instance or recreate it
    }
  }
}




