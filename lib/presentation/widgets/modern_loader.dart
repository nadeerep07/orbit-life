import 'package:flutter/material.dart';

/// A modern, glassmorphic obsidian loader with pulsing gradient rings and optional text.
class ModernGlassLoader extends StatefulWidget {
  final String? message;
  final double size;
  final Color accentColor;

  const ModernGlassLoader({
    super.key,
    this.message,
    this.size = 54.0,
    this.accentColor = const Color(0xFF10B981),
  });

  @override
  State<ModernGlassLoader> createState() => _ModernGlassLoaderState();
}

class _ModernGlassLoaderState extends State<ModernGlassLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        widget.accentColor.withValues(alpha: 0.1),
                        widget.accentColor.withValues(alpha: 0.4),
                        widget.accentColor,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: widget.size * 0.4,
                        height: widget.size * 0.4,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A modern shimmer card placeholder loader for lists and hero sections.
class ModernShimmerLoader extends StatefulWidget {
  final int itemCount;
  final double cardHeight;

  const ModernShimmerLoader({
    super.key,
    this.itemCount = 3,
    this.cardHeight = 76.0,
  });

  @override
  State<ModernShimmerLoader> createState() => _ModernShimmerLoaderState();
}

class _ModernShimmerLoaderState extends State<ModernShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animCtrl,
      builder: (context, child) {
        final opacity = 0.3 + (_animCtrl.value * 0.4);
        return Column(
          children: List.generate(
            widget.itemCount,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              height: widget.cardHeight,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade200)
                    .withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.05),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white12 : Colors.black12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 10,
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white12 : Colors.black12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white12 : Colors.black12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
