import 'package:flutter/material.dart';
import 'package:lucky_wheel/core/constants/app_colors.dart';

/// A fixed ▲ pointer that sits at the top of the wheel.
class PointerIndicator extends StatelessWidget {
  const PointerIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 28,
      child: CustomPaint(
        painter: _PointerPainter(),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.pointerColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path()
      ..moveTo(size.width / 2, size.height) // bottom center
      ..lineTo(0, 0) // top left
      ..lineTo(size.width, 0) // top right
      ..close();

    // Draw shadow first
    final shadowPath = Path()
      ..moveTo(size.width / 2, size.height + 4)
      ..lineTo(-2, -2)
      ..lineTo(size.width + 2, -2)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(shadowPath, shadowPaint);
    canvas.drawPath(path, paint);

    // Highlight on the left edge
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final highlightPath = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(size.width * 0.25, size.height * 0.15);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
