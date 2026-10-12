import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart' show AppDurations, AppSpacing;
import '../../../core/widgets/app_network_image.dart';
import '../../common/l10n_extensions.dart';

/// Opens [urls] full screen at [initialIndex]: swipe between photos,
/// pinch / double-tap to zoom. Uses the root navigator so it covers the tabs.
Future<void> showPhotoViewer(BuildContext context, List<String> urls, int initialIndex) =>
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: AppDurations.medium,
        reverseTransitionDuration: AppDurations.fast,
        pageBuilder: (_, __, ___) => PhotoViewer(urls: urls, initialIndex: initialIndex),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.urls, this.initialIndex = 0});

  final List<String> urls;
  final int initialIndex;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int index) => MediaQuery.disableAnimationsOf(context)
      ? _pages.jumpToPage(index)
      : _pages.animateToPage(index, duration: AppDurations.medium, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A photo viewer is dark in both themes; white controls on black.
    const onPhoto = Colors.white;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: onPhoto,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          color: onPhoto,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Semantics(
          liveRegion: true,
          child: Text(
            l10n.detailsGalleryPhoto(_index + 1, widget.urls.length),
            style: context.textStyles.titleMedium?.copyWith(color: onPhoto),
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.urls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _ZoomablePhoto(
              url: widget.urls[i],
              label: l10n.detailsGalleryPhoto(i + 1, widget.urls.length),
              errorLabel: l10n.destinationImageUnavailable,
            ),
          ),
          // Buttons as well as swiping: a mouse can't drag pages on the web,
          // and they give screen-reader users a way through the photos.
          if (_index > 0)
            PositionedDirectional(
              start: AppSpacing.xs,
              top: 0,
              bottom: 0,
              child: Center(
                child: _PageButton(
                  tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                  icon: Icons.chevron_left, // mirrors itself in RTL (matchTextDirection)
                  onPressed: () => _go(_index - 1),
                ),
              ),
            ),
          if (_index < widget.urls.length - 1)
            PositionedDirectional(
              end: AppSpacing.xs,
              top: 0,
              bottom: 0,
              child: Center(
                child: _PageButton(
                  tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                  icon: Icons.chevron_right,
                  onPressed: () => _go(_index + 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.tooltip, required this.icon, required this.onPressed});

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
        ),
        icon: Icon(icon),
      );
}

class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({required this.url, required this.label, required this.errorLabel});

  final String url;
  final String label;
  final String errorLabel;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  final _transform = TransformationController();
  TapDownDetails? _lastTap;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom(TapDownDetails details) {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed) {
      _transform.value = Matrix4.identity();
    } else {
      final p = details.localPosition;
      // Zoom 2.5× around the tapped point.
      _transform.value = Matrix4.identity()
        ..translateByDouble(-p.dx * 1.5, -p.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: widget.label,
      child: GestureDetector(
        onDoubleTapDown: (d) => _lastTap = d,
        onDoubleTap: () {
          final tap = _lastTap;
          if (tap != null) _toggleZoom(tap);
        },
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: AppNetworkImage(
              url: widget.url,
              fit: BoxFit.contain,
              errorLabel: widget.errorLabel,
            ),
          ),
        ),
      ),
    );
  }
}
