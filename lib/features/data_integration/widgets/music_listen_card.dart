import 'package:flutter/material.dart';
import '../models/music_detail_entry.dart';
import '../services/data_integration_analytics.dart';

class MusicListenCard extends StatelessWidget {
  const MusicListenCard({
    super.key,
    required this.totalCount,
    required this.remainingCount,
    required this.createdAt,
    required this.previewItems,
    required this.source,
    required this.starId,
    this.onTapDetail,
  });

  final int totalCount;
  final int remainingCount;
  final DateTime createdAt;
  final List<MusicDetailItem> previewItems;
  final String source;
  final String starId;
  final VoidCallback? onTapDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTapDetail,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダ
              Text(
                '音楽の再生 $totalCount曲',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // プレビュー行（最大3行）
              ...previewItems.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _obscureText(item.title, 15),
                            style: textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _obscureText(item.artist, 10),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )),
              // 残り件数表示（4件以上の場合）
              if (remainingCount > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '他$remainingCount曲のデータがあります',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // CTAボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    logMusicCardDetailTap(
                      starId: starId,
                      totalCount: totalCount,
                      source: source,
                    );
                    onTapDetail?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.teal.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('この再生履歴の詳細を見る'),
                ),
              ),
              const SizedBox(height: 8),
              // フッター（相対時間）
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatRelativeTime(createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _obscureText(String text, int maxLength) {
    // 無料領域では伏せ字表示（将来有料化前提）
    // 現時点ではモックとして、すべてを伏せ字にする
    final obscured = '♪' * (text.length > maxLength ? maxLength : text.length);
    if (text.length > maxLength) {
      return '$obscured...';
    }
    return obscured;
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'たった今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${difference.inDays}日前';
    }
  }
}

