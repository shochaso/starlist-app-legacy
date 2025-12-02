import "../models/subscription_status.dart";

class SubscriptionValidationService {
  bool isValidSubscription(SubscriptionStatusModel subscription) {
    if (subscription.isExpired || subscription.isCanceled || subscription.isFailed) {
      return false;
    }

    if (subscription.nextBillingDate != null &&
        DateTime.now().isAfter(subscription.nextBillingDate!)) {
      return false;
    }

    return true;
  }

  bool hasAccessToFeature(SubscriptionStatusModel subscription, String feature) {
    if (!isValidSubscription(subscription)) {
      return false;
    }

    // プランに基づく機能アクセスチェック
    // 基本的な機能はすべての有効なサブスクリプションで利用可能
    // プレミアム機能は特定のプランでのみ利用可能
    final planId = subscription.planId?.toLowerCase() ?? '';
    
    // プレミアム機能のチェック
    if (feature == 'premium_content' || feature == 'advanced_analytics') {
      return planId.contains('premium') || planId.contains('pro');
    }
    
    // その他の機能はすべての有効なサブスクリプションで利用可能
    return true;
  }

  bool canUpgrade(SubscriptionStatusModel current, String newPlanId) {
    if (!isValidSubscription(current)) {
      return true; // サブスクリプションがない場合はアップグレード可能
    }

    // プラン階層の定義（簡易版）
    final planHierarchy = ['basic', 'standard', 'premium', 'pro'];
    final currentPlanIndex = planHierarchy.indexWhere(
      (p) => current.planId?.toLowerCase().contains(p) ?? false,
    );
    final newPlanIndex = planHierarchy.indexWhere(
      (p) => newPlanId.toLowerCase().contains(p),
    );

    // 新しいプランが現在のプランより上位の場合、アップグレード可能
    if (currentPlanIndex >= 0 && newPlanIndex > currentPlanIndex) {
      return true;
    }

    return false;
  }

  bool canDowngrade(SubscriptionStatusModel current, String newPlanId) {
    if (!isValidSubscription(current)) {
      return false; // サブスクリプションがない場合はダウングレード不可
    }

    // プラン階層の定義（簡易版）
    final planHierarchy = ['basic', 'standard', 'premium', 'pro'];
    final currentPlanIndex = planHierarchy.indexWhere(
      (p) => current.planId?.toLowerCase().contains(p) ?? false,
    );
    final newPlanIndex = planHierarchy.indexWhere(
      (p) => newPlanId.toLowerCase().contains(p),
    );

    // 新しいプランが現在のプランより下位の場合、ダウングレード可能
    if (currentPlanIndex >= 0 && newPlanIndex >= 0 && newPlanIndex < currentPlanIndex) {
      return true;
    }

    return false;
  }
}
