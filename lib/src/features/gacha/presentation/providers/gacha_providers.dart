import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/gacha_repository.dart';
import '../../data/gacha_repository_impl.dart';
import '../../domain/draw_gacha_usecase.dart';
import '../../models/gacha_models_simple.dart';
import '../../services/gacha_sound_service.dart';
import '../gacha_view_model.dart';

/// ガチャリポジトリプロバイダー
final gachaRepositoryProvider = Provider<GachaRepository>((ref) {
  return GachaRepositoryImpl();
});

/// ガチャユースケースプロバイダー
final drawGachaUsecaseProvider = Provider<DrawGachaUsecase>((ref) {
  final repository = ref.watch(gachaRepositoryProvider);
  return DrawGachaUsecase(repository);
});

/// ガチャ音効果サービスプロバイダー
final gachaSoundServiceProvider = Provider<GachaSoundService>((ref) {
  return GachaSoundService();
});

/// ガチャビューモデルプロバイダー
final gachaViewModelProvider = StateNotifierProvider<GachaViewModel, GachaState>((ref) {
  final usecase = ref.watch(drawGachaUsecaseProvider);
  final soundService = ref.watch(gachaSoundServiceProvider);
  return GachaViewModel(usecase, soundService, ref);
});