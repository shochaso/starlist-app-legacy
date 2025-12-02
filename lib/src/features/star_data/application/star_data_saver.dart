import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:starlist_app/providers/user_provider.dart';
import '../domain/star_data_item.dart';
import '../domain/star_data_repository.dart';
import '../utils/star_id_resolver.dart';
import 'package:starlist_app/src/features/star_data/providers/star_data_providers.dart';

final starDataSaverProvider = Provider<StarDataSaver>((ref) {
  return StarDataSaver(ref);
});

class StarDataSaver {
  StarDataSaver(this._ref);

  final Ref _ref;
  final _uuid = const Uuid();

  Future<void> save({
    required String category,
    required String genre,
    required String title,
    required String subtitle,
    required String source,
    DateTime? occurredAt,
    Map<String, dynamic>? rawPayload,
    String? starIdOverride,
  }) async {
    final repository = _ref.read(starDataRepositoryProvider);
    final now = DateTime.now();
    final starId = starIdOverride ?? _resolveStarId();
    final item = StarDataItem(
      id: _uuid.v4(),
      starId: starId,
      date: occurredAt ?? now,
      category: category,
      genre: genre,
      title: title,
      subtitle: subtitle,
      source: source,
      createdAt: now,
      extra: rawPayload,
    );

    await repository.saveStarDataItem(item);
  }

  String _resolveStarId() {
    final currentUser = _ref.read(currentUserProvider);
    return StarIdResolver.currentUserStarId(
      isLoggedIn: currentUser.id.isNotEmpty,
      isStar: currentUser.isStar,
      username: currentUser.name,
    );
  }
}
