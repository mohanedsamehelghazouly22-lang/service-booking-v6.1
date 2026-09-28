import 'dart:ui';

import 'package:flutter/material.dart';

/// A translucent, blurred "liquid glass" style panel: frosted background,
/// a thin light border, and a soft shadow, so content behind it bleeds
/// through softly instead of a flat solid color.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(20),
    this.blur = 20,
    this.tint,
    this.opacity = 0.55,
    this.borderOpacity = 0.35,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? tint;
  final double opacity;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final base = tint ?? Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: base.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The soft diagonal gradient every "liquid glass" screen sits on top of —
/// glass panels blur and tint this rather than a flat background color.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE9D8),
                Color(0xFFF4C7A7),
                Color(0xFFF0B489),
              ],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: _blob(const Color(0xFFFFFFFF), 220),
        ),
        Positioned(
          bottom: -100,
          left: -70,
          child: _blob(const Color(0xFFF28C28), 260),
        ),
        child,
      ],
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.35),
      ),
    );
  }
}
