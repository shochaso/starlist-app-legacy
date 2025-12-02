import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/birthday_models.dart';

/// 誕生日システムのデータアクセス層
class BirthdayRepository {
  final SupabaseClient _supabase;

  BirthdayRepository({
    required SupabaseClient supabase,
  }) : _supabase = supabase;

  /// ユーザーの誕生日を設定
  Future<void> updateUserBirthday(
    String userId,
    DateTime? birthday,
    BirthdayVisibility visibility,
    bool notificationEnabled,
  ) async {
    try {
      await _supabase.from('profiles').update({
        'birthday': birthday?.toIso8601String().split('T')[0],
        'birthday_visibility': _birthdayVisibilityToString(visibility),
        'birthday_notification_enabled': notificationEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Failed to update user birthday: $e');
    }
  }

  /// 誕生日通知設定を取得
  Future<BirthdayNotificationSetting?> getBirthdayNotificationSetting(
    String userId,
    String starId,
  ) async {
    try {
      final response = await _supabase
          .from('birthday_notification_settings')
          .select()
          .eq('user_id', userId)
          .eq('star_id', starId)
          .maybeSingle();

      if (response == null) return null;
      return BirthdayNotificationSetting.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get birthday notification setting: $e');
    }
  }

  /// ユーザーのすべての誕生日通知設定を取得
  Future<List<BirthdayNotificationSetting>> getUserBirthdayNotificationSettings(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('birthday_notification_settings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response
          .map<BirthdayNotificationSetting>((json) => BirthdayNotificationSetting.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user birthday notification settings: $e');
    }
  }

  /// 誕生日通知設定を更新
  Future<BirthdayNotificationResult> updateBirthdayNotificationSetting(
    String userId,
    String starId,
    bool notificationEnabled,
    String? customMessage,
    int notificationDaysBefore,
  ) async {
    try {
      final response = await _supabase.rpc('update_birthday_notification_setting', params: {
        'p_user_id': userId,
        'p_star_id': starId,
        'p_notification_enabled': notificationEnabled,
        'p_custom_message': customMessage,
        'p_notification_days_before': notificationDaysBefore,
      });

      return BirthdayNotificationResult.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update birthday notification setting: $e');
    }
  }

  /// 誕生日通知を送信
  Future<BirthdayNotificationResult> sendBirthdayNotification(
    String starId,
    BirthdayNotificationType notificationType,
    String? customMessage,
  ) async {
    try {
      final response = await _supabase.rpc('send_birthday_notification', params: {
        'p_star_id': starId,
        'p_notification_type': _notificationTypeToString(notificationType),
        'p_custom_message': customMessage,
      });

      return BirthdayNotificationResult.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send birthday notification: $e');
    }
  }

  /// 今日が誕生日のスターを取得
  Future<List<BirthdayStar>> getBirthdayStarsToday() async {
    try {
      final response = await _supabase.rpc('get_birthday_stars_today');
      
      return (response as List)
          .map<BirthdayStar>((json) => BirthdayStar.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get birthday stars today: $e');
    }
  }

  /// 近日中に誕生日を迎えるスターを取得
  Future<List<BirthdayStar>> getUpcomingBirthdayStars([int daysAhead = 7]) async {
    try {
      final response = await _supabase.rpc('get_upcoming_birthday_stars', params: {
        'days_ahead': daysAhead,
      });
      
      return (response as List)
          .map<BirthdayStar>((json) => BirthdayStar.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming birthday stars: $e');
    }
  }

  /// ユーザーの誕生日通知履歴を取得
  Future<List<BirthdayNotification>> getUserBirthdayNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('birthday_notifications')
          .select()
          .eq('notified_user_id', userId)
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<BirthdayNotification>((json) => BirthdayNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user birthday notifications: $e');
    }
  }

  /// スターの誕生日通知履歴を取得
  Future<List<BirthdayNotification>> getStarBirthdayNotifications(
    String starId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('birthday_notifications')
          .select()
          .eq('star_id', starId)
          .order('sent_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<BirthdayNotification>((json) => BirthdayNotification.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get star birthday notifications: $e');
    }
  }

  /// 誕生日通知を既読にする
  Future<void> markBirthdayNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('birthday_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark birthday notification as read: $e');
    }
  }

  /// 誕生日イベントを作成
  Future<BirthdayEvent> createBirthdayEvent({
    required String starId,
    required String title,
    String? description,
    required DateTime eventDate,
    bool isMilestone = false,
    int? age,
    Map<String, dynamic>? specialRewards,
  }) async {
    try {
      final data = {
        'star_id': starId,
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String().split('T')[0],
        'is_milestone': isMilestone,
        'age': age,
        'special_rewards': specialRewards ?? {},
      };

      final response = await _supabase
          .from('birthday_events')
          .insert(data)
          .select()
          .single();

      return BirthdayEvent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create birthday event: $e');
    }
  }

  /// アクティブな誕生日イベントを取得
  Future<List<BirthdayEvent>> getActiveBirthdayEvents({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('birthday_events')
          .select()
          .eq('is_active', true)
          .order('event_date', ascending: true)
          .range(offset, offset + limit - 1);

      return response
          .map<BirthdayEvent>((json) => BirthdayEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active birthday events: $e');
    }
  }

  /// 特定のスターの誕生日イベントを取得
  Future<List<BirthdayEvent>> getStarBirthdayEvents(
    String starId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('birthday_events')
          .select()
          .eq('star_id', starId)
          .order('event_date', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .map<BirthdayEvent>((json) => BirthdayEvent.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get star birthday events: $e');
    }
  }

  /// 誕生日イベントを更新
  Future<BirthdayEvent> updateBirthdayEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('birthday_events')
          .update(updates)
          .eq('id', eventId)
          .select()
          .single();

      return BirthdayEvent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update birthday event: $e');
    }
  }

  /// 誕生日イベントを非アクティブ化
  Future<void> deactivateBirthdayEvent(String eventId) async {
    try {
      await _supabase
          .from('birthday_events')
          .update({'is_active': false})
          .eq('id', eventId);
    } catch (e) {
      throw Exception('Failed to deactivate birthday event: $e');
    }
  }

  /// フォローしているスターの今日の誕生日を取得
  Future<List<BirthdayStar>> getFollowingStarsBirthdaysToday(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('''
            following:users!follows_following_id_fkey(
              id,
              display_name,
              birthday
            )
          ''')
          .eq('follower_id', userId);

      final today = DateTime.now();
      final birthdayStars = <BirthdayStar>[];

      for (final follow in response) {
        final star = follow['following'];
        if (star != null && star['birthday'] != null) {
          final birthday = DateTime.parse(star['birthday']);
          
          // 今日が誕生日かチェック
          if (birthday.month == today.month && birthday.day == today.day) {
            final age = today.year - birthday.year;
            birthdayStars.add(BirthdayStar(
              starId: star['id'],
              starName: star['display_name'],
              birthday: birthday,
              age: age,
              daysUntilBirthday: 0,
            ));
          }
        }
      }

      return birthdayStars;
    } catch (e) {
      throw Exception('Failed to get following stars birthdays today: $e');
    }
  }

  /// 日次誕生日チェック実行
  Future<void> executeDailyBirthdayCheck() async {
    try {
      await _supabase.rpc('daily_birthday_check');
    } catch (e) {
      throw Exception('Failed to execute daily birthday check: $e');
    }
  }

  /// 誕生日可視性を文字列に変換
  String _birthdayVisibilityToString(BirthdayVisibility visibility) {
    switch (visibility) {
      case BirthdayVisibility.public:
        return 'public';
      case BirthdayVisibility.followers:
        return 'followers';
      case BirthdayVisibility.private:
        return 'private';
    }
  }

  /// 通知タイプを文字列に変換
  String _notificationTypeToString(BirthdayNotificationType type) {
    switch (type) {
      case BirthdayNotificationType.birthdayToday:
        return 'birthday_today';
      case BirthdayNotificationType.birthdayUpcoming:
        return 'birthday_upcoming';
      case BirthdayNotificationType.custom:
        return 'custom';
    }
  }
}