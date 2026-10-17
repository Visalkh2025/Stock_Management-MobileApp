import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens [url] full screen: pinch / double-tap to zoom, drag to pan while
/// zoomed, swipe down (or tap ✕) to close.
Future<void> showProductImageViewer(
  BuildContext context, {
  required String url,
  String? title,
  String? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => ProductImageViewer(url: url, title: title, heroTag: heroTag),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

class ProductImageViewer extends StatefulWidget {
  const ProductImageViewer({super.key, required this.url, this.title, this.heroTag});

  final String url;
  final String? title;
  final String? heroTag;

  @override
  State<ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<ProductImageViewer> with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;
  static const double _dismissDistance = 120;

  final _transform = TransformationController();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapPos = Offset.zero;

  bool _zoomed = false;
  double _dragY = 0;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
    _zoomAnim.addListener(() {
      final t = _zoomTween;
      if (t != null) _transform.value = t.value;
    });
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransformChanged);
    _transform.dispose();
    _zoomAnim.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _toggleZoom() {
    final end = _zoomed
        ? Matrix4.identity()
        : (Matrix4.identity()
            ..translateByDouble(-_doubleTapPos.dx * (_doubleTapScale - 1), -_doubleTapPos.dy * (_doubleTapScale - 1), 0, 1)
            ..scaleByDouble(_doubleTapScale, _doubleTapScale, _doubleTapScale, 1));
    _zoomTween = Matrix4Tween(begin: _transform.value, end: end).animate(
      CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOut),
    );
    _zoomAnim.forward(from: 0);
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    // Background fades out as the image is dragged away.
    final opacity = (1 - (_dragY.abs() / 400)).clamp(0.3, 1.0);

    Widget image = CachedNetworkImage(
      imageUrl: widget.url,
      fit: BoxFit.contain,
      fadeInDuration: const Duration(milliseconds: 150),
      progressIndicatorBuilder: (_, _, progress) => Center(
        child: CircularProgressIndicator(value: progress.progress, color: Colors.white),
      ),
      errorWidget: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 56),
      ),
    );
    if (widget.heroTag != null) image = Hero(tag: widget.heroTag!, child: image);

    return Scaffold(
      backgroundColor: Colors.black.withAlpha((opacity * 255).round()),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
            onDoubleTap: _toggleZoom,
            // Swipe-to-dismiss only while not zoomed (otherwise it pans).
            onVerticalDragUpdate: _zoomed ? null : (d) => setState(() => _dragY += d.delta.dy),
            onVerticalDragEnd: _zoomed
                ? null
                : (d) {
                    final fast = (d.primaryVelocity ?? 0).abs() > 900;
                    if (_dragY.abs() > _dismissDistance || fast) {
                      _close();
                    } else {
                      setState(() => _dragY = 0);
                    }
                  },
            child: Transform.translate(
              offset: Offset(0, _dragY),
              child: SizedBox.expand(
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 5,
                  panEnabled: _zoomed,
                  child: image,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _close,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                  ),
                  if (widget.title != null && widget.title!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
