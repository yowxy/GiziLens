import 'dart:typed_data';

class FrameQuality {
  final bool lighting;
  final bool wholeTray;
  final bool focused;
  final bool withinFrame;

  const FrameQuality({
    required this.lighting,
    required this.wholeTray,
    required this.focused,
    required this.withinFrame,
  });
}

const _sampleStep = 4;
const _borderRatio = 0.08;
const _centerRatio = 0.2;

FrameQuality analyzeLuminanceFrame(
  Uint8List luma, {
  required int width,
  required int height,
  required int bytesPerRow,
}) {
  final borderX = width * _borderRatio;
  final borderY = height * _borderRatio;
  final centerLeft = width * _centerRatio;
  final centerRight = width * (1 - _centerRatio);
  final centerTop = height * _centerRatio;
  final centerBottom = height * (1 - _centerRatio);

  var lumaSum = 0;
  var lumaCount = 0;
  var laplacianSum = 0;
  var centerGradient = 0;
  var centerCount = 0;
  var borderGradient = 0;
  var borderCount = 0;

  for (var y = _sampleStep; y < height - _sampleStep; y += _sampleStep) {
    final rowOffset = y * bytesPerRow;
    final rowStep = _sampleStep * bytesPerRow;
    for (var x = _sampleStep; x < width - _sampleStep; x += _sampleStep) {
      final index = rowOffset + x;
      final center = luma[index];
      final horizontalNeighbours = luma[index - _sampleStep] + luma[index + _sampleStep];
      final verticalNeighbours = luma[index - rowStep] + luma[index + rowStep];
      final gradient = (center - luma[index + _sampleStep]).abs() +
          (center - luma[index + rowStep]).abs();

      lumaSum += center;
      lumaCount++;
      laplacianSum += (2 * center - horizontalNeighbours).abs() +
          (2 * center - verticalNeighbours).abs();

      final inBorder =
          x < borderX || x > width - borderX || y < borderY || y > height - borderY;
      if (inBorder) {
        borderGradient += gradient;
        borderCount++;
      } else if (x >= centerLeft &&
          x <= centerRight &&
          y >= centerTop &&
          y <= centerBottom) {
        centerGradient += gradient;
        centerCount++;
      }
    }
  }

  if (lumaCount == 0 || centerCount == 0 || borderCount == 0) {
    return const FrameQuality(
      lighting: false,
      wholeTray: false,
      focused: false,
      withinFrame: false,
    );
  }

  final meanLuma = lumaSum / lumaCount;
  final meanLaplacian = laplacianSum / lumaCount;
  final meanCenterGradient = centerGradient / centerCount;
  final meanBorderGradient = borderGradient / borderCount;

  return FrameQuality(
    lighting: meanLuma >= 70 && meanLuma <= 215,
    focused: meanLaplacian >= 12,
    withinFrame: meanCenterGradient >= 6,
    wholeTray: meanBorderGradient <= 14,
  );
}
