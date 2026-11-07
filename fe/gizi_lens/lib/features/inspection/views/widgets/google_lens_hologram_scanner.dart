import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoogleLensHologramScanner extends StatefulWidget {
  final Widget? child;
  final bool isScanning;
  final bool showBoundingBoxes;
  final Color beamColor;
  final Color bracketColor;
  final Color boxColor;

  const GoogleLensHologramScanner({
    super.key,
    this.child,
    this.isScanning = true,
    this.showBoundingBoxes = true,
    this.beamColor = const Color(0xFFE5A93C),
    this.bracketColor = const Color(0xFFD6A64B),
    this.boxColor = const Color(0xFFEF4444),
  });

  @override
  State<GoogleLensHologramScanner> createState() => _GoogleLensHologramScannerState();
}

class _GoogleLensHologramScannerState extends State<GoogleLensHologramScanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.child != null) widget.child!,
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _HologramViewfinderPainter(
                    animationValue: _animController.value,
                    isScanning: widget.isScanning,
                    showBoundingBoxes: widget.showBoundingBoxes,
                    beamColor: widget.beamColor,
                    bracketColor: widget.bracketColor,
                    boxColor: widget.boxColor,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HologramViewfinderPainter extends CustomPainter {
  final double animationValue;
  final bool isScanning;
  final bool showBoundingBoxes;
  final Color beamColor;
  final Color bracketColor;
  final Color boxColor;

  _HologramViewfinderPainter({
    required this.animationValue,
    required this.isScanning,
    required this.showBoundingBoxes,
    required this.beamColor,
    required this.bracketColor,
    required this.boxColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final margin = 16.0;
    final rect = Rect.fromLTWH(
      margin,
      margin,
      size.width - (margin * 2),
      size.height - (margin * 2),
    );

    _drawCornerBrackets(canvas, rect);
    _drawDashedBorder(canvas, rect);

    if (isScanning) {
      _drawHolographicLaserBeam(canvas, rect);
      _drawScanningReticle(canvas, rect);
    }

    if (showBoundingBoxes) {
      _drawAiBoundingBoxes(canvas, rect);
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    final bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final armLength = 26.0;
    final r = 10.0;

    final topLeftPath = Path()
      ..moveTo(rect.left, rect.top + armLength)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(
        Offset(rect.left + r, rect.top),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.left + armLength, rect.top);
    canvas.drawPath(topLeftPath, bracketPaint);

    final topRightPath = Path()
      ..moveTo(rect.right - armLength, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + r),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.right, rect.top + armLength);
    canvas.drawPath(topRightPath, bracketPaint);

    final bottomLeftPath = Path()
      ..moveTo(rect.left, rect.bottom - armLength)
      ..lineTo(rect.left, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.left + r, rect.bottom),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.left + armLength, rect.bottom);
    canvas.drawPath(bottomLeftPath, bracketPaint);

    final bottomRightPath = Path()
      ..moveTo(rect.right - armLength, rect.bottom)
      ..lineTo(rect.right - r, rect.bottom)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - r),
        radius: Radius.circular(r),
      )
      ..lineTo(rect.right, rect.bottom - armLength);
    canvas.drawPath(bottomRightPath, bracketPaint);
  }

  void _drawDashedBorder(Canvas canvas, Rect rect) {
    final dashPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    _drawDashedLine(canvas, Offset(rect.left + 28, rect.top), Offset(rect.right - 28, rect.top), dashWidth, dashSpace, dashPaint);
    _drawDashedLine(canvas, Offset(rect.right, rect.top + 28), Offset(rect.right, rect.bottom - 28), dashWidth, dashSpace, dashPaint);
    _drawDashedLine(canvas, Offset(rect.left + 28, rect.bottom), Offset(rect.right - 28, rect.bottom), dashWidth, dashSpace, dashPaint);
    _drawDashedLine(canvas, Offset(rect.left, rect.top + 28), Offset(rect.left, rect.bottom - 28), dashWidth, dashSpace, dashPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, double dashWidth, double dashSpace, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;
    var current = 0.0;

    while (current < distance) {
      final len = math.min(dashWidth, distance - current);
      canvas.drawLine(
        Offset(p1.dx + unitX * current, p1.dy + unitY * current),
        Offset(p1.dx + unitX * (current + len), p1.dy + unitY * (current + len)),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  void _drawHolographicLaserBeam(Canvas canvas, Rect rect) {
    final y = rect.top + (rect.height * animationValue);

    final trailHeight = 44.0;
    final trailRect = Rect.fromLTRB(
      rect.left,
      math.max(rect.top, y - trailHeight),
      rect.right,
      y,
    );

    final trailGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        beamColor.withValues(alpha: 0.0),
        beamColor.withValues(alpha: 0.18),
      ],
    );

    final trailPaint = Paint()
      ..shader = trailGradient.createShader(trailRect);
    canvas.drawRect(trailRect, trailPaint);

    final laserPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          beamColor.withValues(alpha: 0.2),
          Colors.white,
          beamColor,
          Colors.white,
          beamColor.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromLTWH(rect.left, y - 1, rect.width, 2.5))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(rect.left + 4, y), Offset(rect.right - 4, y), laserPaint);

    final glowPaint = Paint()
      ..color = beamColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..strokeWidth = 4.0;
    canvas.drawLine(Offset(rect.left + 6, y), Offset(rect.right - 6, y), glowPaint);
  }

  void _drawScanningReticle(Canvas canvas, Rect rect) {
    final center = rect.center;
    final pulseScale = 0.85 + (0.15 * math.sin(animationValue * math.pi));

    final reticlePaint = Paint()
      ..color = beamColor.withValues(alpha: 0.35 * pulseScale)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 24 * pulseScale, reticlePaint);

    final crossPaint = Paint()
      ..color = beamColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), crossPaint);
  }

  void _drawAiBoundingBoxes(Canvas canvas, Rect rect) {
    final boxPaint = Paint()
      ..color = boxColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final box1 = Rect.fromLTWH(
      rect.left + (rect.width * 0.12),
      rect.top + (rect.height * 0.15),
      rect.width * 0.34,
      rect.height * 0.32,
    );

    final box2 = Rect.fromLTWH(
      rect.left + (rect.width * 0.54),
      rect.top + (rect.height * 0.15),
      rect.width * 0.34,
      rect.height * 0.32,
    );

    final box3 = Rect.fromLTWH(
      rect.left + (rect.width * 0.12),
      rect.top + (rect.height * 0.54),
      rect.width * 0.76,
      rect.height * 0.34,
    );

    _drawAnimatedAiBox(canvas, box1, boxPaint);
    _drawAnimatedAiBox(canvas, box2, boxPaint);
    _drawAnimatedAiBox(canvas, box3, boxPaint);
  }

  void _drawAnimatedAiBox(Canvas canvas, Rect box, Paint paint) {
    final cornerLen = 10.0;

    canvas.drawLine(box.topLeft, Offset(box.left + cornerLen, box.top), paint);
    canvas.drawLine(box.topLeft, Offset(box.left, box.top + cornerLen), paint);

    canvas.drawLine(box.topRight, Offset(box.right - cornerLen, box.top), paint);
    canvas.drawLine(box.topRight, Offset(box.right, box.top + cornerLen), paint);

    canvas.drawLine(box.bottomLeft, Offset(box.left + cornerLen, box.bottom), paint);
    canvas.drawLine(box.bottomLeft, Offset(box.left, box.bottom - cornerLen), paint);

    canvas.drawLine(box.bottomRight, Offset(box.right - cornerLen, box.bottom), paint);
    canvas.drawLine(box.bottomRight, Offset(box.right, box.bottom - cornerLen), paint);

    final fillPaint = Paint()
      ..color = boxColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawRect(box, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _HologramViewfinderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.showBoundingBoxes != showBoundingBoxes;
  }
}
