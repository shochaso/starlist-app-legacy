import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/youtube_watch_detail_entry.dart';
import '../services/youtube_analytics.dart';
import '../widgets/card_helpers.dart';

const _kYoutubeRed = Color(0xFFE50914);

class YoutubeWatchDetailPage extends StatefulWidget {
  const YoutubeWatchDetailPage({
    super.key,
    required this.args,
  });

  final YoutubeWatchDetailArgs? args;

  @override
  State<YoutubeWatchDetailPage> createState() => _YoutubeWatchDetailPageState();
}

class _YoutubeWatchDetailPageState extends State<YoutubeWatchDetailPage> {
  @override
  void initState() {
    super.initState();
    _logDetailOpen();
  }

  void _logDetailOpen() {
    final detail = widget.args;
    if (detail == null || detail.entries.isEmpty) return;
    YoutubeAnalytics.logDetailOpen(
      source: detail.sourceLabel ?? 'unknown',
      videoCount: detail.entries.length,
      firstVideoHasUrl: detail.entries.first.watchUrl?.isNotEmpty ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null || args.entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('YouTube視聴詳細'),
          backgroundColor: Colors.black,
        ),
        body: const Center(
          child: Text('この視聴ログの詳細を表示できませんでした。'),
        ),
      );
    }

    final detail = args;
    final firstUrl = detail.entries.firstWhere(
      (entry) => entry.watchUrl != null && entry.watchUrl!.isNotEmpty,
      orElse: () => detail.entries.first,
    ).watchUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube視聴詳細'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRelativeTime(detail.createdAt, DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (detail.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          detail.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (detail.sourceLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            detail.sourceLabel!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final entry = detail.entries[index];
                      return _YoutubeWatchDetailRow(entry: entry);
                    },
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: detail.entries.length,
                  ),
                ),
                const SizedBox(height: 12),
                if (firstUrl != null && firstUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleOpenYoutube(firstUrl),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kYoutubeRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('YouTubeで開く'),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleOpenYoutube(String url) async {
    final detail = widget.args;
    if (detail != null) {
      await YoutubeAnalytics.logDetailOpenYoutube(
        source: detail.sourceLabel ?? 'unknown',
        videoCount: detail.entries.length,
      );
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
    }
  }
}

class _YoutubeWatchDetailRow extends StatelessWidget {
  const _YoutubeWatchDetailRow({required this.entry});

  final YoutubeWatchDetailEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildThumbnail(context),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                entry.channel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (entry.duration != null && entry.duration!.isNotEmpty)
                    Text(
                      entry.duration!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  const Spacer(),
                  if (entry.watchUrl != null && entry.watchUrl!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      iconSize: 20,
                      onPressed: () => _launchUrl(entry.watchUrl!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final thumbnail = entry.thumbnailUrl;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[300],
        image: thumbnail != null && thumbnail.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(thumbnail),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: thumbnail == null || thumbnail.isEmpty
          ? const Center(child: Icon(Icons.play_circle_outline))
          : null,
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
    }
  }
}


