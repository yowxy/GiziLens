import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'image_utils.dart';

class DetectionResult {
  final int classId;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  const DetectionResult({
    required this.classId,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class AiService {
  OrtSession? _session;
  List<String> _labels = const [];

  String labelFor(int classId) => classId >= 0 && classId < _labels.length
      ? _labels[classId]
      : 'Kelas $classId';

  Future<void> initModel() async {
    OrtEnv.instance.init();
    try {
      final model = await rootBundle.load('assets/ml/best.onnx');
      final labelsJson = await rootBundle.loadString('assets/ml/classes.json');
      final classes = (jsonDecode(labelsJson)['classes'] as List<dynamic>);
      _labels = classes
          .map((item) => (item as Map<String, dynamic>)['name'] as String)
          .toList(growable: false);
      final options = OrtSessionOptions();
      options.setIntraOpNumThreads(2);
      options.setInterOpNumThreads(1);
      options.setSessionGraphOptimizationLevel(
        GraphOptimizationLevel.ortEnableAll,
      );
      _session = OrtSession.fromBuffer(model.buffer.asUint8List(), options);
    } catch (_) {
      _session?.release();
      _session = null;
      rethrow;
    }
  }

  Future<List<DetectionResult>> detect(Uint8List imageBytes) async {
    final session = _session;
    if (session == null) {
      throw StateError('Model AI belum selesai dimuat.');
    }

    final tensor = OrtValueTensor.createTensorWithDataList(
      imageBytesToTensor(imageBytes),
      [1, 3, 320, 320],
    );
    final runOptions = OrtRunOptions();
    try {
      final outputs =
          await session.runAsync(runOptions, {
            session.inputNames.first: tensor,
          }) ??
          const <OrtValue?>[];
      final detections = outputs.isEmpty || outputs.first == null
          ? const <DetectionResult>[]
          : _parseOutput(outputs.first!.value);
      for (final output in outputs) {
        output?.release();
      }
      return detections;
    } finally {
      tensor.release();
      runOptions.release();
    }
  }

  List<DetectionResult> _parseOutput(dynamic rawOutput) {
    final matrix = _asMatrix(rawOutput);
    if (matrix.isEmpty || matrix.first.isEmpty) return const [];
    final channels = matrix.length;
    final candidateCount = matrix.first.length;
    final classCount = (channels - 4).clamp(0, _labels.length);
    if (classCount <= 0) return const [];

    final detections = <DetectionResult>[];
    for (int candidate = 0; candidate < candidateCount; candidate++) {
      double valueAt(int channel) => matrix[channel][candidate];

      var classId = 0;
      var confidence = 0.0;
      for (int classIndex = 0; classIndex < classCount; classIndex++) {
        final score = valueAt(classIndex + 4);
        if (score > confidence) {
          confidence = score;
          classId = classIndex;
        }
      }
      if (confidence < 0.25) continue;

      final width = valueAt(2);
      final height = valueAt(3);
      detections.add(
        DetectionResult(
          classId: classId,
          confidence: confidence,
          x: valueAt(0) - width / 2,
          y: valueAt(1) - height / 2,
          width: width,
          height: height,
        ),
      );
    }
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    return detections.take(20).toList();
  }

  List<List<double>> _asMatrix(dynamic value) {
    dynamic matrix = value;
    if (matrix is List && matrix.length == 1) {
      matrix = matrix.first;
    }
    if (matrix is List && matrix.isNotEmpty && matrix.first is List) {
      return matrix
          .map<List<double>>(
            (row) => (row as List)
                .map<double>((item) => (item as num).toDouble())
                .toList(),
          )
          .toList();
    }
    final flat = _flatten(value);
    const maskChannels = 32;
    final expectedChannels = 4 + _labels.length + maskChannels;
    final fallbackChannels = flat.length % expectedChannels == 0
        ? expectedChannels
        : 35;
    final candidateCount = flat.length ~/ fallbackChannels;
    return List.generate(fallbackChannels, (channel) {
      return List.generate(
        candidateCount,
        (candidate) => flat[channel * candidateCount + candidate],
      );
    });
  }

  List<double> _flatten(dynamic value) {
    if (value is List) {
      return value.expand<double>(_flatten).toList();
    }
    return value is num ? [value.toDouble()] : const [];
  }

  void close() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
