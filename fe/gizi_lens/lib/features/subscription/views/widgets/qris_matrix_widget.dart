import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Deterministic QR-style matrix painter rendered from [payload] so QRIS
/// checkout displays an authentic scannable-style pattern with finder squares
/// and a centered GiziLens badge without requiring external QR packages.
class QrisMatrixWidget extends StatelessWidget {
  final String payload;
  final double size;

  const QrisMatrixWidget({
    super.key,
    required this.payload,
    this.size = 188,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6DFD5), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size - 28, size - 28),
            painter: _QrMatrixPainter(payload: payload),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryForest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String payload;

  _QrMatrixPainter({required this.payload});

  static const int _gridSize = 21;

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / _gridSize;
    final darkPaint = Paint()..color = AppColors.primaryDark;
    final lightPaint = Paint()..color = Colors.white;

    canvas.drawRect(Offset.zero & size, lightPaint);

    // Build deterministic pseudo-random data bits from payload
    var hash = 2166136261;
    for (final code in payload.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    for (var row = 0; row < _gridSize; row++) {
      for (var col = 0; col < _gridSize; col++) {
        if (_isInFinderZone(row, col) || _isInCenterLogoZone(row, col)) {
          continue;
        }
        // Timing strips on row 6 and col 6
        final isModuleDark = (row == 6 || col == 6)
            ? (row + col) % 2 == 0
            : _deterministicBit(hash, row, col);

        if (isModuleDark) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                col * cellSize + 0.4,
                row * cellSize + 0.4,
                cellSize - 0.8,
                cellSize - 0.8,
              ),
              const Radius.circular(1.2),
            ),
            darkPaint,
          );
        }
      }
    }

    // Draw 3 QR finder patterns (top-left, top-right, bottom-left)
    _drawFinderPattern(canvas, cellSize, 0, 0, darkPaint, lightPaint);
    _drawFinderPattern(
      canvas,
      cellSize,
      0,
      _gridSize - 7,
      darkPaint,
      lightPaint,
    );
    _drawFinderPattern(
      canvas,
      cellSize,
      _gridSize - 7,
      0,
      darkPaint,
      lightPaint,
    );
  }

  bool _isInFinderZone(int r, int c) {
    final topLeft = r < 8 && c < 8;
    final topRight = r < 8 && c >= _gridSize - 8;
    final bottomLeft = r >= _gridSize - 8 && c < 8;
    return topLeft || topRight || bottomLeft;
  }

  bool _isInCenterLogoZone(int r, int c) {
    return r >= 8 && r <= 12 && c >= 8 && c <= 12;
  }

  bool _deterministicBit(int seed, int r, int c) {
    final v = (seed ^ (r * 73856093) ^ (c * 19349663)) & 0x7fffffff;
    return (v % 11) < 6;
  }

  void _drawFinderPattern(
    Canvas canvas,
    double cellSize,
    int startRow,
    int startCol,
    Paint darkPaint,
    Paint lightPaint,
  ) {
    final x = startCol * cellSize;
    final y = startRow * cellSize;
    final outer = 7 * cellSize;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, outer, outer),
        const Radius.circular(4),
      ),
      darkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize),
        const Radius.circular(2.5),
      ),
      lightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + 2 * cellSize,
          y + 2 * cellSize,
          3 * cellSize,
          3 * cellSize,
        ),
        const Radius.circular(1.5),
      ),
      darkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) =>
      oldDelegate.payload != payload;
}
