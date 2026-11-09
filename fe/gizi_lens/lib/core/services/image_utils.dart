import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

Float32List cameraImageToTensor(CameraImage cameraImage) {
  return imageToTensor(_convertYUV420ToImage(cameraImage));
}

Float32List imageBytesToTensor(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Citra kamera tidak dapat dibaca.');
  }
  return imageToTensor(decoded);
}

Float32List imageToTensor(img.Image source) {
  final rgbImage = img.bakeOrientation(source);

  const inputSize = 320;
  final resizedImage = img.copyResize(
    rgbImage,
    width: inputSize,
    height: inputSize,
  );

  final int area = inputSize * inputSize;
  final input = Float32List(3 * area);

  int pixelIndex = 0;
  for (int y = 0; y < inputSize; y++) {
    for (int x = 0; x < inputSize; x++) {
      final pixel = resizedImage.getPixel(x, y);
      input[pixelIndex] = pixel.r / 255.0; // Red
      input[pixelIndex + area] = pixel.g / 255.0; // Green
      input[pixelIndex + (area * 2)] = pixel.b / 255.0; // Blue

      pixelIndex++;
    }
  }

  return input;
}

img.Image _convertYUV420ToImage(CameraImage image) {
  final output = img.Image(width: image.width, height: image.height);
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final yIndex = y * yPlane.bytesPerRow + x;
      final uvX = x ~/ 2;
      final uvY = y ~/ 2;
      final uIndex = uvY * uPlane.bytesPerRow + uvX * uPlane.bytesPerPixel!;
      final vIndex = uvY * vPlane.bytesPerRow + uvX * vPlane.bytesPerPixel!;

      final yValue = yPlane.bytes[yIndex];
      final uValue = uPlane.bytes[uIndex];
      final vValue = vPlane.bytes[vIndex];
      final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
      final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .round()
          .clamp(0, 255);
      final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
      output.setPixelRgb(x, y, r, g, b);
    }
  }
  return output;
}
