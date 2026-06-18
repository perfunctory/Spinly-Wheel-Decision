import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucky_wheel/core/constants/app_colors.dart';

/// CustomPainter that draws the wheel with sectors, text, and center.
class WheelPainter extends CustomPainter {
  const WheelPainter({
    required this.options,
    required this.rotation,
  });

  final List<String> options;
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    if (options.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectorAngle = 2 * math.pi / options.length;

    // --- Draw sectors ---
    for (var i = 0; i < options.length; i++) {
      final startAngle = rotation + i * sectorAngle;

      // Fill with color
      final paint = Paint()
        ..color = sectorColors[i % sectorColors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        sectorAngle,
        true,
        paint,
      );

      // Sector border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        sectorAngle,
        true,
        borderPaint,
      );

      // Draw text label
      _drawSectorText(
        canvas,
        options[i],
        center,
        radius * 0.62,
        startAngle + sectorAngle / 2,
        sectorAngle,
      );
    }

    // --- Outer decorative ring ---
    final outerRingPaint = Paint()
      ..color = AppColors.wheelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius - 2, outerRingPaint);

    // --- Decorative dots around the rim ---
    final dotPaint = Paint()
      ..color = AppColors.pointerColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const dotCount = 36;
    const dotRadius = 3.0;
    for (var i = 0; i < dotCount; i++) {
      final angle = i * (2 * math.pi / dotCount);
      final dotCenter = Offset(
        center.dx + (radius - 14) * math.cos(angle),
        center.dy + (radius - 14) * math.sin(angle),
      );
      canvas.drawCircle(dotCenter, dotRadius, dotPaint);
    }

    // --- Center circle ---
    final centerGradient = RadialGradient(
      center: Alignment.center,
      colors: [
        Colors.white,
        AppColors.wheelCenter,
      ],
    );

    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.22),
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.22, centerPaint);

    // Center border
    final centerBorderPaint = Paint()
      ..color = AppColors.wheelBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius * 0.22, centerBorderPaint);

    // Center inner dot
    final innerDotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.06, innerDotPaint);
  }

  void _drawSectorText(
    Canvas canvas,
    String text,
    Offset center,
    double textRadius,
    double midAngle,
    double sectorAngle,
  ) {
    // Position text at the midpoint of the sector
    final x = center.dx + textRadius * math.cos(midAngle);
    final y = center.dy + textRadius * math.sin(midAngle);

    canvas.save();
    canvas.translate(x, y);
    // Rotate so text reads outward from center
    canvas.rotate(midAngle + math.pi / 2);

    // Truncate text if too long for the sector
    final displayText = _truncateText(text, sectorAngle, textRadius);

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: _contrastColor(sectorColors[
              options.indexOf(text) % sectorColors.length]),
          fontSize: _calculateFontSize(options.length),
          fontWeight: FontWeight.w700,
          shadows: const [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: textRadius * 0.5);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );

    canvas.restore();
  }

  /// Picks black or white text for best contrast against the background.
  Color _contrastColor(Color background) {
    final r = (background.r * 255.0).round().clamp(0, 255);
    final g = (background.g * 255.0).round().clamp(0, 255);
    final b = (background.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.6 ? AppColors.text : Colors.white;
  }

  /// Scales font size based on option count.
  double _calculateFontSize(int optionCount) {
    if (optionCount <= 4) return 18;
    if (optionCount <= 6) return 16;
    if (optionCount <= 10) return 14;
    if (optionCount <= 15) return 12;
    return 10;
  }

  /// Truncates text if it won't fit in the sector.
  String _truncateText(String text, double sectorAngle, double textRadius) {
    // Estimate available chars based on arc length
    final arcLength = sectorAngle * textRadius;
    final estimatedMaxChars = (arcLength / 10).floor().clamp(4, 12);

    if (text.length > estimatedMaxChars) {
      return '${text.substring(0, estimatedMaxChars - 1)}…';
    }
    return text;
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) =>
      options != oldDelegate.options || rotation != oldDelegate.rotation;
}
