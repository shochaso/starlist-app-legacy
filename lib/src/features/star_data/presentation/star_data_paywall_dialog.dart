import 'package:flutter/material.dart';
import 'dart:ui';

/// Dialog showing subscription plans for accessing premium star data.
class PaywallPlansDialog extends StatelessWidget {
  const PaywallPlansDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with rich gradient background
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                            : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Icon(Icons.diamond_outlined,
                                size: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Unlock Full Access',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '有料プラン限定データ',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ショッピング・音楽・レシートなどの詳細データや\n分析レポートは有料プランで閲覧できます。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: -20,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEC4899).withOpacity(0.05),
                      ),
                    ),
                  ),
                ],
              ),

              // Plans Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      // Light Plan
                      _buildPlanCard(
                        context,
                        title: 'ライトプラン',
                        price: '¥980',
                        description: 'まずは気軽に始めたい方へ',
                        features: ['直近3ヶ月のデータ閲覧', '一部カテゴリの閲覧'],
                        color: const Color(0xFF0EA5E9),
                        badge: 'ENTRY',
                      ),
                      const SizedBox(height: 16),
                      
                      // Standard Plan
                      _buildPlanCard(
                        context,
                        title: 'スタンダードプラン',
                        price: '¥1,980',
                        description: '一番人気の標準プラン',
                        features: [
                          '全データの閲覧制限なし',
                          '過去アーカイブへのアクセス',
                          '新着優先通知',
                        ],
                        isRecommended: true,
                        color: const Color(0xFF6366F1),
                        badge: 'POPULAR',
                      ),
                      const SizedBox(height: 16),

                      // Premium Plan
                      _buildPlanCard(
                        context,
                        title: 'プレミアムプラン',
                        price: '¥2,980',
                        description: '究極のファン体験を',
                        features: [
                          '全ての機能にフルアクセス',
                          '特別タグ付きデータの閲覧',
                          '限定コンテンツ・イベント招待',
                          '優先サポートデスク',
                        ],
                        color: const Color(0xFFD946EF),
                        isPremium: true,
                        badge: 'VIP',
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    '閉じる',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required List<String> features,
    required Color color,
    bool isRecommended = false,
    bool isPremium = false,
    String? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRecommended ? color : const Color(0xFFE2E8F0),
              width: isRecommended ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isRecommended ? 0.15 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: isPremium
                ? LinearGradient(
                    colors: [Colors.white, color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$title を選択しました')),
                );
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isRecommended || isPremium
                                    ? color
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              price,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '/月',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 16),
                    ...features.map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check, size: 10, color: color),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$title を選択しました')),
                          );
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: isRecommended || isPremium ? color : const Color(0xFFF1F5F9),
                          foregroundColor: isRecommended || isPremium ? Colors.white : const Color(0xFF475569),
                          elevation: isRecommended || isPremium ? 8 : 0,
                          shadowColor: isRecommended || isPremium ? color.withOpacity(0.4) : null,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'このプランにする',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: 16,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


