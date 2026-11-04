import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class MascotViewfinder extends StatelessWidget {
  const MascotViewfinder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ViewfinderSurroundPainter(),
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    AppAssets.mascotLensy,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'AI',
                      style: AppTypography.badge.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderSurroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderMedium
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.borderMedium
      ..style = PaintingStyle.fill;

    const pad = 12.0;
    final w = size.width;
    final h = size.height;
    const l = 14.0;

    canvas.drawLine(const Offset(pad, pad + l), const Offset(pad, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + l, pad), paint);

    canvas.drawLine(Offset(w - pad - l, pad), Offset(w - pad, pad), paint);
    canvas.drawLine(Offset(w - pad, pad), Offset(w - pad, pad + l), paint);

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(pad + 2 + col * 4.0, h - pad - 6 + row * 4.0),
          1.2,
          dotPaint,
        );
      }
    }

    canvas.drawLine(Offset(w - pad - l, h - pad), Offset(w - pad, h - pad), paint);
    canvas.drawLine(Offset(w - pad, h - pad - l), Offset(w - pad, h - pad), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
