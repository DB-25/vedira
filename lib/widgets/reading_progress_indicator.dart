import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// A widget that displays reading progress as the user scrolls through content
class ReadingProgressIndicator extends StatefulWidget {
  final ScrollController scrollController;
  final double height;
  final Color? activeColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showPercentage;

  const ReadingProgressIndicator({
    super.key,
    required this.scrollController,
    this.height = AppConstants.progressBarHeight,
    this.activeColor,
    this.backgroundColor,
    this.borderRadius,
    this.showPercentage = false,
  });

  @override
  State<ReadingProgressIndicator> createState() =>
      _ReadingProgressIndicatorState();
}

class _ReadingProgressIndicatorState extends State<ReadingProgressIndicator>
    with SingleTickerProviderStateMixin {
  double _progressValue = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: AppConstants.progressAnimationDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!widget.scrollController.hasClients) return;

    final maxScrollExtent = widget.scrollController.position.maxScrollExtent;
    final currentPosition = widget.scrollController.offset;

    // Calculate progress (0.0 to 1.0)
    double newProgress = 0.0;
    if (maxScrollExtent > 0) {
      newProgress = (currentPosition / maxScrollExtent).clamp(0.0, 1.0);
    }

    if (newProgress != _progressValue) {
      setState(() {
        _progressValue = newProgress;
      });

      // Animate the progress change
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use theme colors instead of hardcoded constants
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;
    final backgroundColor =
        widget.backgroundColor ?? theme.colorScheme.onSurface.withOpacity(0.1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                  minHeight: widget.height,
                ),
              ),
              if (widget.showPercentage) ...[
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '${(_progressValue * 100).round()}%',
                    key: ValueKey(_progressValue),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A more advanced scroll indicator that mimics a scrollbar
class ScrollIndicator extends StatefulWidget {
  final ScrollController scrollController;
  final double width;
  final Color? trackColor;
  final Color? thumbColor;
  final double thumbHeight;
  final BorderRadius? borderRadius;

  const ScrollIndicator({
    super.key,
    required this.scrollController,
    this.width = AppConstants.scrollIndicatorWidth,
    this.trackColor,
    this.thumbColor,
    this.thumbHeight = AppConstants.scrollIndicatorThumbHeight,
    this.borderRadius,
  });

  @override
  State<ScrollIndicator> createState() => _ScrollIndicatorState();
}

class _ScrollIndicatorState extends State<ScrollIndicator> {
  double _thumbPosition = 0.0;
  double _availableHeight = 0.0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (!widget.scrollController.hasClients || _availableHeight <= 0) return;

    final maxScrollExtent = widget.scrollController.position.maxScrollExtent;
    final currentPosition = widget.scrollController.offset;

    if (maxScrollExtent > 0) {
      final progress = (currentPosition / maxScrollExtent).clamp(0.0, 1.0);
      final maxThumbPosition = _availableHeight - widget.thumbHeight;

      setState(() {
        _thumbPosition = progress * maxThumbPosition;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use theme colors instead of hardcoded constants
    final trackColor =
        widget.trackColor ?? theme.colorScheme.onSurface.withOpacity(0.1);
    final thumbColor = widget.thumbColor ?? theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        _availableHeight = constraints.maxHeight;

        return Container(
          width: widget.width,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(widget.width / 2),
          ),
          child: Stack(
            children: [
              Positioned(
                top: _thumbPosition,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: AppConstants.progressAnimationDuration,
                  height: widget.thumbHeight,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(widget.width / 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
