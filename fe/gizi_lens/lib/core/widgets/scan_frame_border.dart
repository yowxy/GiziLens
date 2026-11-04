import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ScanViewfinderFrame extends StatelessWidget {
  final Widget child;
  final Color bracketColor;
  final double bracketLength;
  final double bracketThickness;
  final double cornerRadius;
  final EdgeInsetsGeometry padding;

  const ScanViewfinderFrame({
    super.key,
    required this.child,
    this.bracketColor = AppColors.primaryDark,
    this.bracketLength = 16.0,
    this.bracketThickness = 2.5,
    this.cornerRadius = 4.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ViewfinderPainter(
        color: bracketColor,
        bracketLength: bracketLength,
        thickness: bracketThickness,
        radius: cornerRadius,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  final Color color;
  final double bracketLength;
  final double thickness;
  final double radius;

  _ViewfinderPainter({
    required this.color,
    required this.bracketLength,
    required this.thickness,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final l = bracketLength;
    final r = radius;

    final pathTL = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(l, 0);
    canvas.drawPath(pathTL, paint);

    final pathTR = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, l);
    canvas.drawPath(pathTR, paint);

    final pathBL = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..quadraticBezierTo(0, h, r, h)
      ..lineTo(l, h);
    canvas.drawPath(pathBL, paint);

    final pathBR = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..quadraticBezierTo(w, h, w, h - r)
      ..lineTo(w, h - l);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.bracketLength != bracketLength ||
        oldDelegate.thickness != thickness ||
        oldDelegate.radius != radius;
  }
}
