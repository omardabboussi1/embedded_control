import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusIndicator extends StatefulWidget {
  final bool isActive;
  final String label;
  final Color activeColor;
  final double size;

  const StatusIndicator({
    super.key,
    required this.isActive,
    required this.label,
    this.activeColor = AppTheme.accentGreen,
    this.size = 10,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive
                    ? widget.activeColor
                    : AppTheme.textMuted,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: widget.activeColor.withOpacity(
                            0.5 * _pulseAnimation.value,
                          ),
                          blurRadius: 8 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value,
                        ),
                      ]
                    : [],
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: TextStyle(
            color: widget.isActive
                ? AppTheme.textPrimary
                : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
