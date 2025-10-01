import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Card with pixel/cube grid that fills based on progress (HabitKit style)
class PixelGridMacroCard extends StatefulWidget {
  final String title;
  final double current;
  final double target;
  final String unit;
  final Color color;

  const PixelGridMacroCard({
    super.key,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  State<PixelGridMacroCard> createState() => _PixelGridMacroCardState();
}

class _PixelGridMacroCardState extends State<PixelGridMacroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fillAnimation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final progress = _computeProgress(widget.current, widget.target);
    _previousProgress = progress;
    _fillAnimation = Tween<double>(begin: 0, end: progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant PixelGridMacroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = _computeProgress(widget.current, widget.target);

    if ((newProgress - _previousProgress).abs() > 0.01) {
      _fillAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
      );
      _animationController.forward(from: 0);
      _previousProgress = newProgress;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _computeProgress(double current, double target) {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.23);
    final bg = Theme.of(context).colorScheme.surface;
    final progress = _computeProgress(widget.current, widget.target);
    final percentage = (progress * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  percentage >= 100 ? '100%+' : '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: percentage >= 100 ? Colors.green : widget.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pixel grid
          Expanded(
            child: AnimatedBuilder(
              animation: _fillAnimation,
              builder: (context, child) {
                return PixelGrid(
                  progress: _fillAnimation.value,
                  color: widget.color,
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Values
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.current.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ ${widget.target.toStringAsFixed(0)} ${widget.unit}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget that renders the pixel grid
class PixelGrid extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;

  static const int rows = 8;
  static const int cols = 14;
  static const double pixelGap = 3;
  static const double pixelRadius = 2;

  const PixelGrid({
    super.key,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final totalPixels = rows * cols;
    final filledPixels = (totalPixels * progress).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Calculate size to make pixels square
        final pixelWidth = (availableWidth - (cols - 1) * pixelGap) / cols;
        final pixelHeight = (availableHeight - (rows - 1) * pixelGap) / rows;
        final pixelSize = math.min(pixelWidth, pixelHeight);

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(rows, (rowIndex) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(cols, (colIndex) {
                // Fill from bottom to top, left to right within each row
                final reversedRow = rows - 1 - rowIndex;
                final pixelIndex = reversedRow * cols + colIndex;
                final isFilled = pixelIndex < filledPixels;

                // Calculate opacity based on how recently filled
                double opacity = 1.0;
                if (isFilled) {
                  final distanceFromEdge = filledPixels - pixelIndex;
                  if (distanceFromEdge <= 3) {
                    // Recent pixels are brighter
                    opacity = 0.6 + (distanceFromEdge / 3) * 0.4;
                  }
                }

                return Container(
                  width: pixelSize,
                  height: pixelSize,
                  decoration: BoxDecoration(
                    color: isFilled
                        ? color.withValues(alpha: opacity)
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(pixelRadius),
                  ),
                );
              }),
            );
          }),
        );
      },
    );
  }
}