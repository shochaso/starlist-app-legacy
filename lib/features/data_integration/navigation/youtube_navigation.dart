import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/youtube_watch_detail_entry.dart';

const String youtubeWatchDetailRouteName = 'youtube-watch-detail';

void navigateToYoutubeWatchDetail(
  BuildContext context,
  YoutubeWatchDetailArgs args,
) {
  GoRouter.of(context).pushNamed(
    youtubeWatchDetailRouteName,
    extra: args,
  );
}


