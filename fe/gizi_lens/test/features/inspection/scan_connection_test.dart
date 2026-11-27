import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/features/inspection/controllers/scan_ompreng_controller.dart';
import 'package:gizi_lens/features/inspection/views/scan_ompreng_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late ScanOmprengController controller;
  final photo = XFile.fromData(Uint8List.fromList([1]));

  setUp(() async {
    controller = ScanOmprengController();
    await controller.initializeModel();
  });
  tearDown(() => controller.dispose());

  testWidgets('A stalled response body times out and allows another scan', (
    tester,
  ) async {
    final body = StreamController<List<int>>();
    final scan = http.runWithClient(
      () => controller.capturePhoto(photo),
      () => MockClient.streaming(
        (_, _) async => http.StreamedResponse(body.stream, 200),
      ),
    );
    await tester.pump();
    expect(controller.isAnalyzing, isTrue);
    await tester.pump(const Duration(seconds: 90));
    expect(await scan, isFalse);
    expect(controller.isAnalyzing, isFalse);
    expect(controller.errorMessage, contains('Server belum merespons'));
    await body.close();

    final retry = http.runWithClient(
      () => controller.capturePhoto(photo),
      () => MockClient((_) async => http.Response('{"items":[]}', 200)),
    );
    expect(controller.errorMessage, isNull);
    expect(await retry, isFalse);
    expect(controller.errorMessage, contains('Makanan belum terdeteksi'));
  });

  test('A provider timeout displays the reason sent by the backend', () async {
    const detail = 'Layanan AI terlalu lama merespons. Coba lagi.';
    final result = await http.runWithClient(
      () => controller.capturePhoto(photo),
      () => MockClient((_) async => http.Response('{"detail":"$detail"}', 504)),
    );
    expect(result, isFalse);
    expect(controller.errorMessage, detail);
    expect(controller.isAnalyzing, isFalse);
  });

  test('computeCameraPreviewBoxSize preserves native 16:9 and 4:3 portrait ratios', () {
    final portrait16x9 = ScanOmprengScreen.computeCameraPreviewBoxSize(
      const Size(1280, 720),
      DeviceOrientation.portraitUp,
    );
    expect(portrait16x9.width / portrait16x9.height, closeTo(9 / 16, 0.001));

    final portrait4x3 = ScanOmprengScreen.computeCameraPreviewBoxSize(
      const Size(1600, 1200),
      DeviceOrientation.portraitUp,
    );
    expect(portrait4x3.width / portrait4x3.height, closeTo(3 / 4, 0.001));

    final landscape16x9 = ScanOmprengScreen.computeCameraPreviewBoxSize(
      const Size(1280, 720),
      DeviceOrientation.landscapeLeft,
    );
    expect(landscape16x9.width / landscape16x9.height, closeTo(16 / 9, 0.001));
  });
}
