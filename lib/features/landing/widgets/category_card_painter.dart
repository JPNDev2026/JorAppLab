import 'package:flutter/material.dart';

class CategoryCardPainter extends CustomPainter {
  final Color accentColor;
  final Color lime;

  const CategoryCardPainter({
    required this.accentColor,
    required this.lime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()
      ..color = accentColor.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    final rectPaint = Paint()
      ..color = accentColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.24), 34, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.76, size.height * 0.28), 22, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.58, size.height * 0.78), 40, circlePaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.58, 78, 24),
        const Radius.circular(12),
      ),
      rectPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.12, 58, 20),
        const Radius.circular(10),
      ),
      rectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
