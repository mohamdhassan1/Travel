import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Cached remote image with a neutral placeholder and a labelled fallback.
///
/// Sends an identifying User-Agent (Wikimedia's policy for hotlinked
/// images; browsers set their own on web).
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.errorLabel,
    this.cacheWidth,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final String? errorLabel;

  /// Decode width in logical pixels — keeps memory low for list thumbnails.
  final int? cacheWidth;

  /// Shown while loading and if the image fails (e.g. initials for avatars).
  final Widget? fallback;

  static const _headers = {
    'User-Agent': 'Rahala/1.0 (Flutter travel app; https://github.com/mohamdhassan1/Travel)',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: kIsWeb ? null : _headers,
      fit: fit,
      memCacheWidth: cacheWidth == null ? null : (cacheWidth! * dpr).round(),
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, __) => fallback ?? ColoredBox(color: colors.surfaceContainerHigh),
      errorWidget: (_, __, ___) =>
          fallback ??
          ColoredBox(
            color: colors.surfaceContainerHigh,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: colors.onSurfaceVariant,
                semanticLabel: errorLabel,
              ),
            ),
          ),
    );
  }
}
