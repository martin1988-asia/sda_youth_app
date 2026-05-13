// lib/widgets/titan_shimmer.dart
import 'package:flutter/material.dart';

/// TitanShimmer — World-class skeleton loader for SDA Youth.
/// Provides a cinematic animated gradient to reduce perceived latency.
class TitanShimmer extends StatefulWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const TitanShimmer.rectangular({
    super.key, 
    this.width = double.infinity, 
    required this.height
  }) : shapeBorder = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)));

  const TitanShimmer.circular({
    super.key, 
    required this.width, 
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  State<TitanShimmer> createState() => _TitanShimmerState();
}

class _TitanShimmerState extends State<TitanShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            shape: widget.shapeBorder,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.1, 0.5, 0.9],
              colors: [
                Colors.white.withValues(alpha: 0.05),
                const Color(0xFF00FFCC).withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
              transform: _SlidingGradientTransform(offset: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double offset;
  const _SlidingGradientTransform({required this.offset});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * offset, 0.0, 0.0);
  }
}

/// Helper to build a full skeleton post card
class ShimmerPost extends StatelessWidget {
  const ShimmerPost({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TitanShimmer.circular(width: 40, height: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitanShimmer.rectangular(height: 12, width: MediaQuery.of(context).size.width * 0.3),
                  const SizedBox(height: 6),
                  TitanShimmer.rectangular(height: 8, width: MediaQuery.of(context).size.width * 0.2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const TitanShimmer.rectangular(height: 14),
          const SizedBox(height: 10),
          const TitanShimmer.rectangular(height: 14),
          const SizedBox(height: 20),
          const TitanShimmer.rectangular(height: 200), // Image skeleton
        ],
      ),
    );
  }
}
