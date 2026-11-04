import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SplashWatermarkPainter extends CustomPainter {
  final Color color;

  const SplashWatermarkPainter({
    this.color = AppColors.watermarkLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final rrect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, -20, w * 0.36, h * 0.16),
      const Radius.circular(24),
    );
    canvas.save();
    canvas.rotate(-0.06);
    canvas.drawRRect(rrect1, paint);
    canvas.restore();

    final rrect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.62, -20, w * 0.36, h * 0.18),
      const Radius.circular(24),
    );
    canvas.save();
    canvas.rotate(-0.04);
    canvas.drawRRect(rrect2, paint);
    canvas.restore();

    final rrect3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.13, w * 0.32, h * 0.15),
      const Radius.circular(28),
    );
    canvas.save();
    canvas.rotate(-0.05);
    canvas.drawRRect(rrect3, paint);
    _drawLeaf(canvas, Offset(w * 0.44, h * 0.21), paint);
    canvas.restore();

    final rrect4 = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.65, h * 0.15, w * 0.30, h * 0.16),
      const Radius.circular(28),
    );
    canvas.save();
    canvas.rotate(-0.03);
    canvas.drawRRect(rrect4, paint);
    _drawFlower(canvas, Offset(w * 0.80, h * 0.24), paint, fillPaint);
    canvas.restore();

    _drawCutlery(canvas, Offset(w * 0.52, 24), paint);
    _drawFruit(canvas, Offset(w * 0.95, h * 0.07), paint);
  }

  void _drawLeaf(Canvas canvas, Offset center, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - 14, center.dy)
      ..quadraticBezierTo(center.dx - 10, center.dy - 16, center.dx + 12, center.dy - 12)
      ..quadraticBezierTo(center.dx + 16, center.dy + 8, center.dx - 14, center.dy);
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy - 8),
      paint..strokeWidth = 1.2,
    );
    paint.strokeWidth = 1.8;
  }

  void _drawFlower(Canvas canvas, Offset center, Paint paint, Paint fillPaint) {
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * 3.14159 / 5);
      final petalOffset = Offset(
        center.dx + 9 * (angle == 0 ? 1 : (angle > 0 && angle < 3.14 ? 0.7 : -0.7)),
        center.dy + 9 * (angle > 1.5 && angle < 4.5 ? 0.7 : -0.7),
      );
      canvas.drawCircle(petalOffset, 4.5, paint);
    }
    canvas.drawCircle(center, 4, paint);
  }

  void _drawCutlery(Canvas canvas, Offset center, Paint paint) {
    final p = Path()
      ..moveTo(center.dx - 6, center.dy - 14)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..lineTo(center.dx + 6, center.dy - 14)
      ..moveTo(center.dx - 2, center.dy - 14)
      ..lineTo(center.dx - 2, center.dy)
      ..moveTo(center.dx + 2, center.dy - 14)
      ..lineTo(center.dx + 2, center.dy)
      ..moveTo(center.dx, center.dy)
      ..lineTo(center.dx, center.dy + 20);
    canvas.drawPath(p, paint);
  }

  void _drawFruit(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, 12, paint);
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx + 2, center.dy - 18),
      paint,
    );
    final leaf = Path()
      ..moveTo(center.dx + 2, center.dy - 16)
      ..quadraticBezierTo(center.dx + 8, center.dy - 18, center.dx + 7, center.dy - 14)
      ..quadraticBezierTo(center.dx + 4, center.dy - 13, center.dx + 2, center.dy - 16);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant SplashWatermarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
