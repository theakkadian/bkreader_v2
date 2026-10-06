import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/reader_bloc.dart';

/// Pinch-zoom overlay. Uses setState only for AnimationController ticker glue.
class ZoomableImage extends StatefulWidget {
  const ZoomableImage({super.key, required this.imageWidget});

  final Widget imageWidget;

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  OverlayEntry? _entry;
  double _scale = 1;
  static const double _minScale = 1;
  static const double _maxScale = 4;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )
      ..addListener(() {
        _controller.value = _animation!.value;
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _removeOverlay();
        }
      });
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showOverlay(BuildContext context) {
    if (_entry != null) return;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final offset = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;

    _entry = OverlayEntry(
      builder: (context) {
        final opacity = ((_scale - 1) / (_maxScale - 1)).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: opacity,
                child: const ColoredBox(color: Colors.black),
              ),
            ),
            Positioned(
              top: offset.dy,
              left: offset.dx,
              width: size.width,
              height: size.height,
              child: _buildViewer(context, forOverlay: true),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  Widget _buildViewer(BuildContext context, {bool forOverlay = false}) {
    return InteractiveViewer(
      transformationController: _controller,
      clipBehavior: Clip.none,
      minScale: _minScale,
      maxScale: _maxScale,
      onInteractionStart: (details) {
        if (forOverlay) return;
        if (details.pointerCount < 2) return;
        _showOverlay(context);
        context.read<ReaderBloc>().add(const ToggleZoom(true));
      },
      onInteractionUpdate: (details) {
        if (_entry == null) return;
        _scale = details.scale;
        _entry!.markNeedsBuild();
      },
      onInteractionEnd: (_) {
        if (forOverlay) return;
        _resetAnimation();
        context.read<ReaderBloc>().add(const ToggleZoom(false));
      },
      child: SizedBox.expand(child: widget.imageWidget),
    );
  }

  void _resetAnimation() {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward(from: 0);
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
    _scale = 1;
  }

  @override
  Widget build(BuildContext context) => _buildViewer(context);
}
