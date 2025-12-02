import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/ui_flags.dart';
import '../../utils/key_normalizer.dart';
import '../../widgets/icon_diag_hud.dart';
import 'service_icon_cache.dart';
import 'service_icon_registry.dart' as registry;
import 'service_icon_sources.dart' show ServiceIconResolution;

class ServiceIcon extends StatefulWidget {
  const ServiceIcon.forKey(
    this._keyName, {
    super.key,
    this.size = 24,
    this.fallback,
    this.fit = BoxFit.contain,
  }) : assetPath = null;

  const ServiceIcon.asset(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.fallback,
    this.fit = BoxFit.contain,
  }) : _keyName = null;

  final String? _keyName;
  final String? assetPath;
  final double size;
  final IconData? fallback;
  final BoxFit fit;

  bool get _shouldHideImportImages => kHideImportImages && _keyName != null;

  @override
  State<ServiceIcon> createState() => _ServiceIconState();
}

class _ServiceIconState extends State<ServiceIcon> {
  Future<ServiceIconResolution?>? _resolutionFuture;
  String? _normalizedKey;

  @override
  void initState() {
    super.initState();
    _prepareResolutionFuture();
  }

  @override
  void didUpdateWidget(covariant ServiceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._keyName != oldWidget._keyName) {
      _prepareResolutionFuture();
    }
  }

  void _prepareResolutionFuture() {
    if (widget._keyName == null) {
      _resolutionFuture = null;
      _normalizedKey = null;
      return;
    }
    final requestedKey = widget._keyName!;
    _normalizedKey = KeyNormalizer.normalize(requestedKey);
    _resolutionFuture =
        registry.ServiceIconRegistry.instance.resolve(requestedKey);
  }

  bool get _shouldHideImportImages =>
      widget._shouldHideImportImages && widget._keyName != null;

  @override
  Widget build(BuildContext context) {
    if (_shouldHideImportImages) {
      return SizedBox.square(dimension: widget.size);
    }
    if (widget.assetPath != null) {
      return _buildAssetIcon(widget.assetPath!);
    }
    return _buildDynamicIcon();
  }

  Widget _buildDynamicIcon() {
    final requestedKey = widget._keyName!;
    final normalized = _normalizedKey ?? KeyNormalizer.normalize(requestedKey);
    final future = _resolutionFuture;

    return FutureBuilder<ServiceIconResolution?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholder();
        }

        if (snapshot.hasError) {
          recordIconDiag(
            IconDiagEvent(
              key: normalized,
              origin: normalized,
              source: ServiceIconSourceType.fallback,
              duration: Duration.zero,
              fallback: true,
            ),
          );
          return _buildFallbackIcon();
        }

        final resolution = snapshot.data;
        if (resolution == null ||
            resolution.payload.bytes.isEmpty ||
            resolution.sourceType == ServiceIconSourceType.fallback) {
          recordIconDiag(
            IconDiagEvent(
              key: normalized,
              origin: resolution?.originPath ?? 'missing',
              source: resolution?.sourceType ?? ServiceIconSourceType.fallback,
              duration: resolution?.duration ?? Duration.zero,
              cacheHit: resolution?.cacheHit ?? false,
              fallback: true,
            ),
          );
          return _buildFallbackIcon();
        }

        final effectiveSource = resolution.cacheHit
            ? (resolution.originalSource ?? resolution.sourceType)
            : resolution.sourceType;
        recordIconDiag(
          IconDiagEvent(
            key: normalized,
            origin: resolution.originPath,
            source: effectiveSource,
            duration: resolution.duration,
            cacheHit: resolution.cacheHit,
            fallback: false,
          ),
        );

        final payload = resolution.payload;
        try {
          return _buildAnimated(
            payload.isSvg
                ? SvgPicture.memory(
                    payload.bytes,
                    width: widget.size,
                    height: widget.size,
                    fit: widget.fit,
                    colorFilter: null,
                    clipBehavior: Clip.antiAlias,
                    placeholderBuilder: (_) => _buildPlaceholder(),
                  )
                : Image.memory(
                    payload.bytes,
                    width: widget.size,
                    height: widget.size,
                    fit: widget.fit,
                    filterQuality: FilterQuality.high,
                  ),
          );
        } catch (error) {
          if (payload.isSvg) {
            ServiceIconCache.clear();
          }
          recordIconDiag(
            IconDiagEvent(
              key: normalized,
              origin: resolution.originPath,
              source: ServiceIconSourceType.fallback,
              duration: resolution.duration,
              cacheHit: resolution.cacheHit,
              fallback: true,
            ),
          );
          return _buildFallbackIcon();
        }
      },
    );
  }

  Widget _buildAssetIcon(String path) {
    final isSvg = path.toLowerCase().endsWith('.svg');
    final normalized =
        widget._keyName != null ? KeyNormalizer.normalize(widget._keyName!) : path;

    try {
      final iconWidget = isSvg
          ? SvgPicture.asset(
              path,
              width: widget.size,
              height: widget.size,
              fit: widget.fit,
              clipBehavior: Clip.antiAlias,
            )
          : Image.asset(
              path,
              width: widget.size,
              height: widget.size,
              fit: widget.fit,
              filterQuality: FilterQuality.high,
            );
      recordIconDiag(
        IconDiagEvent(
          key: normalized,
          origin: path,
          source: isSvg
              ? ServiceIconSourceType.assetSvg
              : ServiceIconSourceType.assetPng,
          duration: Duration.zero,
        ),
      );
      return _buildAnimated(iconWidget);
    } catch (_) {
      recordIconDiag(
        IconDiagEvent(
          key: normalized,
          origin: path,
          source: ServiceIconSourceType.fallback,
          duration: Duration.zero,
          fallback: true,
        ),
      );
      return _buildFallbackIcon();
    }
  }

  Widget _buildAnimated(Widget child) {
    return SizedBox.square(
      dimension: widget.size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, value, _) => Opacity(opacity: value, child: child),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return SizedBox.square(
      dimension: widget.size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(widget.size * 0.2),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    final icon = widget.fallback ?? Icons.image_not_supported_outlined;
    return SizedBox.square(
      dimension: widget.size,
      child: Icon(icon, size: widget.size * 0.7),
    );
  }
}
