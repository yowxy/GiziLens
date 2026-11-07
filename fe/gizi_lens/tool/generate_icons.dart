// ignore_for_file: avoid_print, depend_on_referenced_packages
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputBytes = File('referensi/icon.png').readAsBytesSync();
  final source = img.decodeImage(inputBytes);
  if (source == null) {
    print('Failed to decode referensi/icon.png');
    exit(1);
  }
  print('Source size: ${source.width}x${source.height}');

  // 1. Master Icon (1024x1024) for iOS and Legacy Android with White Background
  // Lensy centered at ~70% scale so it breathes nicely in the icon frame.
  final masterSize = 1024;
  final masterIcon = img.Image(width: masterSize, height: masterSize);
  // Fill background with white
  img.fill(masterIcon, color: img.ColorRgb8(255, 255, 255));

  final targetHeightMaster = 720;
  final targetWidthMaster = (targetHeightMaster * source.width / source.height).round();
  final resizedMaster = img.copyResize(source, width: targetWidthMaster, height: targetHeightMaster, interpolation: img.Interpolation.linear);

  final posXMaster = ((masterSize - targetWidthMaster) / 2).round();
  final posYMaster = ((masterSize - targetHeightMaster) / 2).round();
  img.compositeImage(masterIcon, resizedMaster, dstX: posXMaster, dstY: posYMaster);

  File('assets/images/app_icon.png').writeAsBytesSync(img.encodePng(masterIcon));
  print('Generated assets/images/app_icon.png (1024x1024)');

  // 2. Adaptive Icon Foreground (1024x1024) with transparent background
  // Safe zone for Android Adaptive Icon is 66% (radius 33% from center).
  // Target height 620px ensures everything (magnifying glass, ears, feet) is 100% inside the circle mask.
  final adaptiveFore = img.Image(width: masterSize, height: masterSize, numChannels: 4);
  img.fill(adaptiveFore, color: img.ColorRgba8(0, 0, 0, 0));

  final targetHeightAdaptive = 620;
  final targetWidthAdaptive = (targetHeightAdaptive * source.width / source.height).round();
  final resizedAdaptive = img.copyResize(source, width: targetWidthAdaptive, height: targetHeightAdaptive, interpolation: img.Interpolation.linear);

  final posXAdaptive = ((masterSize - targetWidthAdaptive) / 2).round();
  final posYAdaptive = ((masterSize - targetHeightAdaptive) / 2).round();
  img.compositeImage(adaptiveFore, resizedAdaptive, dstX: posXAdaptive, dstY: posYAdaptive);

  File('assets/images/app_icon_foreground.png').writeAsBytesSync(img.encodePng(adaptiveFore));
  print('Generated assets/images/app_icon_foreground.png (1024x1024)');
}
