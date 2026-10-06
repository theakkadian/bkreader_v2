import 'package:flutter/material.dart';

/// Tablet / large-screen layout helpers.
class Responsive {
  Responsive._();

  /// Material tablet breakpoint (shortest side).
  static const double tabletBreakpoint = 600;

  /// Max readable content width on tablets.
  static const double contentMaxWidth = 720;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= tabletBreakpoint;

  /// Height-based size with higher caps on tablets.
  static double scaled(
    BuildContext context,
    double value, {
    required double min,
    required double max,
  }) {
    if (isTablet(context)) {
      return value.clamp(min * 1.1, max * 1.3);
    }
    return value.clamp(min, max);
  }
}

/// Centers [child] and caps width on tablets; phones stay full-bleed.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = Responsive.contentMaxWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final content = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    if (!Responsive.isTablet(context)) {
      return content;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.hasBoundedHeight
                ? constraints.maxHeight
                : null,
            child: content,
          ),
        );
      },
    );
  }
}
