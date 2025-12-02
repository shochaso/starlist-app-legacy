import 'package:starlist_app/features/data_integration/models/intake_response.dart';

/// UI 向けにシンプルにした YouTube プレビュー（タイトル + チャンネル）のみ。
/// IntakeResponse のサムネ／URL などはここでは扱わず、Aパターンの表示に集中。
class YoutubePreviewEntry {
  const YoutubePreviewEntry({
    required this.title,
    required this.channel,
  });

  /// Builds a preview entry from an [IntakeItem].
  factory YoutubePreviewEntry.fromIntakeItem(IntakeItem item) {
    return YoutubePreviewEntry(
      title: item.title,
      channel: item.channel,
    );
  }

  final String title;
  final String channel;
}


