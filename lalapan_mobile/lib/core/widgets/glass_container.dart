import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Glassmorphism Container with smooth blur, translucent borders,
/// and optional hover/active elevation for Web & Mobile.
class GlassContainer extends StatefulWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? baseColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Border? border;
  final List<BoxShadow>? shadows;
  final bool enableHover;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.78,
    this.baseColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.shadows,
    this.enableHover = false,
    this.onTap,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20.0);

    final defaultBaseColor = isDark
        ? const Color(0xFF0F172A)
        : Colors.white;

    final effectiveColor = (widget.baseColor ?? defaultBaseColor).withValues(
      alpha: widget.opacity.clamp(0.0, 1.0),
    );

    final defaultBorderColor = isDark
        ? (_isHovered
            ? Colors.blue.shade400.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.15))
        : (_isHovered
            ? Colors.blue.shade600.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.60));

    final effectiveBorder = widget.border ??
        Border.all(
          color: defaultBorderColor,
          width: _isHovered ? 1.5 : 1.0,
        );

    final defaultShadows = widget.shadows ??
        [
          BoxShadow(
            color: _isHovered
                ? Colors.blue.shade900.withValues(alpha: isDark ? 0.35 : 0.12)
                : const Color(0xFF0F172A).withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: _isHovered ? 28.0 : 20.0,
            offset: Offset(0, _isHovered ? 6 : 4),
          ),
        ];

    Widget glassBody = ClipRRect(
      borderRadius: effectiveRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: widget.padding ?? const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: effectiveColor,
            borderRadius: effectiveRadius,
            border: effectiveBorder,
            boxShadow: defaultShadows,
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      glassBody = InkWell(
        onTap: widget.onTap,
        borderRadius: effectiveRadius,
        child: glassBody,
      );
    }

    if (widget.enableHover) {
      glassBody = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: glassBody,
        ),
      );
    }

    if (widget.margin != null) {
      return Padding(
        padding: widget.margin!,
        child: glassBody,
      );
    }

    return glassBody;
  }
}
