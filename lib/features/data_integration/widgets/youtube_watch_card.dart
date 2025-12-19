import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/intake_response.dart';
import '../models/youtube_preview_entry.dart';
import '../services/youtube_analytics.dart';
import 'card_helpers.dart';

/// YouTube視聴カード（縦長Aパターン v1.1.1）
///
/// 最新仕様:
/// - 完全テキスト3行のプレビュー（アイコン・サムネイルなし）
/// - 左側: タイトル（最大15文字 + `…`）、右側: チャンネル名（最大10文字 + `…`）を右寄せ
/// - `他◯本の動画を視聴`（最大件数に応じて1行）+ `このデータの詳細を見る` CTA
/// - 最下部に `X時間前` / `X日前` の相対時間
class YoutubeWatchCard extends StatelessWidget {
  const YoutubeWatchCard({
    super.key,
    required this.totalCount,
    required this.previews,
    required this.createdAt,
    this.onTapDetail,
    this.source = 'unknown',
  }) : assert(
          previews.length <= _CardConstants.maxPreviewRows,
          'YoutubeWatchCard supports at most ${_CardConstants.maxPreviewRows} preview rows.',
        );

  /// コンストラクタ: IntakeResponse から生成
  factory YoutubeWatchCard.fromIntakeResponse(
    IntakeResponse response, {
    DateTime? createdAt,
    VoidCallback? onTapDetail,
    String source = 'intake',
  }) {
    final previewEntries = response.items
        .map(YoutubePreviewEntry.fromIntakeItem)
        .take(_CardConstants.maxPreviewRows)
        .toList();
    final parsedCreatedAt = createdAt ??
        DateTime.tryParse(response.health?.timestamp ?? '') ??
        DateTime.now(); // Intake 側に timestamp があれば尊重、それ以外は「いま」を採用。
    return YoutubeWatchCard(
      totalCount: response.items.length,
      previews: previewEntries,
      createdAt: parsedCreatedAt,
      onTapDetail: onTapDetail,
      source: source,
    );
  }

  final int totalCount;
  final List<YoutubePreviewEntry> previews;
  final DateTime createdAt;
  final VoidCallback? onTapDetail;
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = math.max(totalCount - previews.length, 0);
    final now = DateTime.now();

    // Aパターン: テキスト3行＋(必要なら)残件数＋CTA＋時刻という構成のみ。アイコンもサムネも描画しない。
    return Card(
      margin: _CardConstants.cardMargin,
      elevation: _CardConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_CardConstants.cardRadius),
      ),
      child: Container(
        padding: _CardConstants.cardPadding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_CardConstants.cardRadius),
          gradient: _CardGradients.getGradient(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'YouTube視聴動画 $totalCount本',
              style: _TextStyles.titleStyle(isDark),
            ),
            const SizedBox(height: _CardConstants.sectionSpacing),
            ..._buildPreviewRows(isDark),
            if (remaining > 0) ...[
              const SizedBox(height: _CardConstants.remainingTopSpacing),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '他${remaining}本の動画を視聴',
                  style: _TextStyles.remainingTextStyle(isDark),
                ),
              ),
            ],
            const SizedBox(height: _CardConstants.ctaTopSpacing),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTapDetail == null ? null : _handleDetailTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _CardColors.youtubeRed,
                  foregroundColor: Colors.white,
                  padding: _CardConstants.ctaPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_CardConstants.ctaRadius),
                  ),
                ),
                child: Text(
                  'このデータの詳細を見る',
                  style: _TextStyles.ctaButtonText,
                ),
              ),
            ),
            const SizedBox(height: _CardConstants.footerTopSpacing),
            Text(
              formatRelativeTime(createdAt, now),
              style: _TextStyles.footerTextStyle(isDark),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPreviewRows(bool isDark) {
    if (previews.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.only(bottom: _CardConstants.previewRowSpacing),
          child: Text(
            '動画が見つかりませんでした',
            style: _TextStyles.emptyStateStyle(isDark),
          ),
        ),
      ];
    }

    final rows = <Widget>[];
    for (var index = 0; index < previews.length; index++) {
      final entry = previews[index];
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: index < previews.length - 1 ? _CardConstants.previewRowSpacing : 0,
          ),
          child: _buildPreviewRow(entry, isDark),
        ),
      );
    }
    return rows;
  }

  void _handleDetailTap() {
    YoutubeAnalytics.logCardDetailTap(
      source: source,
      videoCount: totalCount,
      createdAt: createdAt,
    );
    onTapDetail?.call();
  }

  Widget _buildPreviewRow(YoutubePreviewEntry entry, bool isDark) {
    final channelLabel = entry.channel.isNotEmpty ? entry.channel : 'チャンネル不明';
    // タイトルは左、右端にチャンネル名を合わせることで縦方向にも右揃えを維持。
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '・${truncateForTitle(entry.title)}',
            style: _TextStyles.previewTitleStyle(isDark),
          ),
        ),
        const SizedBox(width: _CardConstants.previewChannelSpacing),
        Flexible(
          child: Text(
            truncateForChannel(channelLabel),
            style: _TextStyles.previewChannelStyle(isDark),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// Card spacing and layout constants
class _CardConstants {
  _CardConstants._();

  static const cardMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  static const cardElevation = 2.0;
  static const cardRadius = 20.0;
  static const cardPadding = EdgeInsets.all(20);
  static const sectionSpacing = 16.0;
  static const previewRowSpacing = 12.0;
  static const previewChannelSpacing = 8.0;
  static const remainingTopSpacing = 10.0;
  static const ctaTopSpacing = 14.0;
  static const ctaPadding = EdgeInsets.symmetric(vertical: 12);
  static const ctaRadius = 12.0;
  static const footerTopSpacing = 12.0;
  static const maxPreviewRows = 3;
}

/// Visual constants (colors)
class _CardColors {
  _CardColors._();

  static const navy = Color(0xFF1A1F2E);
  static const darkNavy = Color(0xFF1E2A3A);
  static const lightBackgroundStart = Color(0xFFF8F9FA);
  static const lightBackgroundEnd = Color(0xFFFFFFFF);
  static const youtubeRed = Color(0xFFE50914);
}

class _CardGradients {
  _CardGradients._();

  static LinearGradient getGradient(bool isDark) {
    return isDark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _CardColors.navy,
              _CardColors.darkNavy,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _CardColors.lightBackgroundStart,
              _CardColors.lightBackgroundEnd,
            ],
          );
  }
}

/// Text styles
class _TextStyles {
  _TextStyles._();

  static TextStyle titleStyle(bool isDark) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : _CardColors.navy,
      letterSpacing: -0.5,
    );
  }

  static TextStyle previewTitleStyle(bool isDark) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : _CardColors.navy,
      height: 1.2,
    );
  }

  static TextStyle previewChannelStyle(bool isDark) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.grey[300] : Colors.grey[700],
    );
  }

  static TextStyle remainingTextStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.grey[300] : Colors.grey[700],
    );
  }

  static TextStyle ctaButtonText = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle footerTextStyle(bool isDark) {
    return TextStyle(
      fontSize: 12,
      color: isDark ? Colors.grey[400] : Colors.grey[600],
    );
  }

  static TextStyle emptyStateStyle(bool isDark) {
    return TextStyle(
      fontSize: 14,
      color: isDark ? Colors.grey[400] : Colors.grey[500],
      fontWeight: FontWeight.w500,
    );
  }
}



