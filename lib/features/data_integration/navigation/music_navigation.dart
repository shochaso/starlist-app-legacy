import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/music_detail_entry.dart';

void navigateToMusicDetail(
  BuildContext context,
  MusicDetailEntry entry, {
  String source = 'star_data',
}) {
  context.push(
    '/music/detail',
    extra: MusicDetailArgs(
      entry: entry,
      source: source,
    ),
  );
}

class MusicDetailArgs {
  const MusicDetailArgs({
    required this.entry,
    required this.source,
  });

  final MusicDetailEntry entry;
  final String source;
}



