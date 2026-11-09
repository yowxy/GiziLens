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
  State<GoogleLensHologramScanner> createState() =>
      _GoogleLensHologramScannerState();
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
    final trayRect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.18,
      size.width * 0.88,
      size.height * 0.64,
    );

    _drawTrayGuide(canvas, trayRect);

    if (isScanning) {
      _drawHolographicLaserBeam(canvas, trayRect);
      _drawScanningReticle(canvas, trayRect);
    }
  }

  void _drawTrayGuide(Canvas canvas, Rect trayRect) {
    final outlinePaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final compartmentPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final fillPaint = Paint()
      ..color = bracketColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(trayRect, const Radius.circular(18)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(trayRect, const Radius.circular(18)),
      outlinePaint,
    );

    final topHeight = trayRect.height * 0.48;
    final gap = trayRect.width * 0.035;
    final topY = trayRect.top + gap;
    final bottomY = trayRect.top + topHeight + gap * 1.2;
    final topWidth = (trayRect.width - gap * 4) / 3;
    final left = trayRect.left + gap;

    for (var index = 0; index < 3; index++) {
      final x = left + index * (topWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, topY, topWidth, topHeight - gap),
          const Radius.circular(14),
        ),
        compartmentPaint,
      );
    }

    final bottomHeight = trayRect.bottom - bottomY - gap;
    final bottomLeftWidth = trayRect.width * 0.31;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          trayRect.left + gap,
          bottomY,
          bottomLeftWidth,
          bottomHeight,
        ),
        const Radius.circular(18),
      ),
      compartmentPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          trayRect.left + gap * 2 + bottomLeftWidth,
          bottomY,
          trayRect.width - bottomLeftWidth - gap * 3,
          bottomHeight,
        ),
        const Radius.circular(18),
      ),
      compartmentPaint,
    );
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

    final trailPaint = Paint()..shader = trailGradient.createShader(trailRect);
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

    canvas.drawLine(
      Offset(rect.left + 4, y),
      Offset(rect.right - 4, y),
      laserPaint,
    );

    final glowPaint = Paint()
      ..color = beamColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..strokeWidth = 4.0;
    canvas.drawLine(
      Offset(rect.left + 6, y),
      Offset(rect.right - 6, y),
      glowPaint,
    );
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

    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HologramViewfinderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.showBoundingBoxes != showBoundingBoxes;
  }
}
