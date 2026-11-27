import 'dart:typed_data';

import 'package:flutter/material.dart';

const List<Color> kBboxColors = [
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFFEF4444),
  Color(0xFF14B8A6),
];

Color bboxColorForIndex(int index) => kBboxColors[index % kBboxColors.length];

/// Shows the captured ompreng photo with the AI bounding boxes and labels.
class AnnotatedScanImage extends StatelessWidget {
  const AnnotatedScanImage({
    super.key,
    required this.imageUrl,
    required this.components,
    this.imageBytes,
    this.aspectRatio,
    this.height,
    this.width,
    this.showLabels = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  final String? imageUrl;
  final Uint8List? imageBytes;

  /// Width / height of the photo. When set, the widget keeps that ratio so the
  /// bounding boxes stay aligned with the image instead of being cropped.
  final double? aspectRatio;
  final List<Map<String, dynamic>> components;
  final double? height;
  final double? width;
  final bool showLabels;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final boxes = _boxes();
    final content = Stack(
      fit: StackFit.expand,
      children: [
        if (imageBytes != null && imageBytes!.isNotEmpty)
          Image.memory(
            imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          )
        else if (imageUrl != null && imageUrl!.isNotEmpty)
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _placeholder(loading: true);
            },
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          )
        else
          _placeholder(),
        if (boxes.isNotEmpty)
          CustomPaint(
            painter: _BoundingBoxPainter(
              boxes: boxes,
              showLabels: showLabels,
            ),
          ),
      ],
    );

    final ratio = aspectRatio;
    if (ratio != null && ratio > 0) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(aspectRatio: ratio, child: content),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: content,
      ),
    );
  }

  List<_BboxItem> _boxes() {
    final result = <_BboxItem>[];
    for (var index = 0; index < components.length; index++) {
      final bbox = components[index]['bbox'];
      if (bbox is! Map) continue;
      final x = _toDouble(bbox['x']);
      final y = _toDouble(bbox['y']);
      final width = _toDouble(bbox['width']);
      final height = _toDouble(bbox['height']);
      if (width <= 0 || height <= 0) continue;
      result.add(
        _BboxItem(
          label: components[index]['name']?.toString() ?? 'Komponen',
          x: x,
          y: y,
          width: width,
          height: height,
          color: bboxColorForIndex(index),
        ),
      );
    }
    return result;
  }

  Widget _placeholder({bool loading = false}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE7F0E8), Color(0xFFD5E4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.restaurant_rounded,
                color: Color(0xFF6B8573),
                size: 28,
              ),
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _BboxItem {
  const _BboxItem({
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color color;
}

class _BoundingBoxPainter extends CustomPainter {
  _BoundingBoxPainter({required this.boxes, required this.showLabels});

  final List<_BboxItem> boxes;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = showLabels ? 2.2 : 1.6
      ..strokeCap = StrokeCap.round;

    for (final box in boxes) {
      final rect = Rect.fromLTWH(
        box.x.clamp(0.0, 1.0).toDouble() * size.width,
        box.y.clamp(0.0, 1.0).toDouble() * size.height,
        box.width.clamp(0.0, 1.0).toDouble() * size.width,
        box.height.clamp(0.0, 1.0).toDouble() * size.height,
      );
      stroke.color = box.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        stroke,
      );

      if (!showLabels) continue;
      final label = _buildLabel(box.label, box.color);
      final labelWidth = label.width + 10;
      final labelHeight = label.height + 4;
      final left = rect.left.clamp(0.0, size.width - labelWidth).toDouble();
      final top = (rect.top - labelHeight - 2)
          .clamp(0.0, size.height - labelHeight)
          .toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, labelWidth, labelHeight),
          const Radius.circular(4),
        ),
        Paint()..color = box.color,
      );
      label.paint(canvas, Offset(left + 5, top + 2));
    }
  }

  TextPainter _buildLabel(String text, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 110);
    return painter;
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes || oldDelegate.showLabels != showLabels;
  }
}
