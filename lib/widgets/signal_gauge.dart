import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignalGauge extends StatefulWidget {
  final int signalStrength; // 0-100
  final double size;

  const SignalGauge({
    super.key,
    required this.signalStrength,
    this.size = 120,
  });

  @override
  State<SignalGauge> createState() => _SignalGaugeState();
}

class _SignalGaugeState extends State<SignalGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.signalStrength.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SignalGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signalStrength != widget.signalStrength) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.signalStrength.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(double value) {
    if (value > 70) return AppTheme.accentGreen;
    if (value > 40) return AppTheme.accentOrange;
    return AppTheme.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final color = _getColor(currentValue);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              value: currentValue,
              color: color,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${currentValue.round()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Signal',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: widget.size * 0.1,
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

class _GaugePainter extends CustomPainter {
  final double value; // 0-100
  final Color color;

  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const startAngle = 2.356; // 135 degrees in radians
    const sweepRange = 4.712; // 270 degrees

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.dividerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange,
      false,
      bgPaint,
    );

    // Value arc
    final valuePaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepRange * (value / 100),
        colors: [
          color.withOpacity(0.4),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepRange * (value / 100),
      false,
      valuePaint,
    );

    // Glow effect at the end
    if (value > 0) {
      final endAngle = startAngle + sweepRange * (value / 100);
      final glowX = center.dx + radius * cos(endAngle);
      final glowY = center.dy + radius * sin(endAngle);

      final glowPaint = Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(glowX, glowY), 6, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}
