import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../features/inspection/models/target_akg_model.dart';

/// A single food item returned by the GiziLens detection backend.
class ApiFoodItem {
  final String name;
  final String category;
  final int estimatedGram;
  final double confidence;
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrate;
  final double fiber;
  final Rect? boundingBox;

  const ApiFoodItem({
    required this.name,
    required this.category,
    required this.estimatedGram,
    required this.confidence,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbohydrate,
    required this.fiber,
    this.boundingBox,
  });
}

class DetectionApiResult {
  final List<ApiFoodItem> items;
  final String engine;
  final String model;
  final String summary;
  final String akgAssessment;

  const DetectionApiResult({
    required this.items,
    required this.engine,
    required this.model,
    required this.summary,
    required this.akgAssessment,
  });
}

/// Client for the FastAPI detection service in `backend/`.
///
/// All LLM / ONNX inference happens server-side; the app only uploads the photo.
class DetectionApiService {
  String get _baseUrl =>
      (dotenv.env['BACKEND_BASE_URL'] ?? 'http://10.0.2.2:8000')
          .replaceAll(RegExp(r'/+$'), '');
  String get _apiKey => dotenv.env['BACKEND_API_KEY'] ?? '';

  Future<DetectionApiResult> analyzeImage(
    Uint8List imageBytes, {
    required TargetAkgModel target,
    String engine = 'auto',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/v1/detect'),
    );

    if (_apiKey.isNotEmpty) {
      request.headers['X-API-Key'] = _apiKey;
    }

    request.fields
      ..['engine'] = engine
      ..['target_group'] = target.groupName
      ..['target_calories'] = target.lunchCalories.toStringAsFixed(2)
      ..['target_protein'] = target.lunchProtein.toStringAsFixed(2)
      ..['target_fat'] = target.lunchFat.toStringAsFixed(2)
      ..['target_carbohydrate'] = target.lunchCarbohydrate.toStringAsFixed(2)
      ..['target_fiber'] = target.lunchFiber.toStringAsFixed(2);

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'ompreng.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessage(response));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (payload['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseItem)
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);

    return DetectionApiResult(
      items: items,
      engine: _string(payload['engine'], fallback: 'unknown'),
      model: _string(payload['model'], fallback: 'unknown'),
      summary: _string(payload['summary']),
      akgAssessment: _string(payload['akg_assessment']),
    );
  }

  String _errorMessage(http.Response response) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map<String, dynamic> && payload['detail'] != null) {
        return 'API deteksi gagal (${response.statusCode}): ${payload['detail']}';
      }
    } catch (_) {
      // Fall through to the raw body below.
    }
    return 'API deteksi gagal (${response.statusCode}): ${response.body}';
  }

  ApiFoodItem _parseItem(Map<String, dynamic> item) {
    final nutrition = item['nutrition'] as Map<String, dynamic>? ?? const {};
    return ApiFoodItem(
      name: _string(item['name']),
      category: _string(item['category'], fallback: 'Lainnya'),
      estimatedGram: _number(item['estimated_gram']).round().clamp(1, 2000),
      confidence: _number(item['confidence']).clamp(0, 1),
      calories: _number(nutrition['calories']),
      protein: _number(nutrition['protein']),
      fat: _number(nutrition['fat']),
      carbohydrate: _number(nutrition['carbohydrate']),
      fiber: _number(nutrition['fiber']),
      boundingBox: _rect(item['bbox']),
    );
  }

  Rect? _rect(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final x = _number(value['x']).clamp(0.0, 1.0);
    final y = _number(value['y']).clamp(0.0, 1.0);
    final width = _number(value['width']).clamp(0.0, 1.0 - x);
    final height = _number(value['height']).clamp(0.0, 1.0 - y);
    if (width <= 0 || height <= 0) return null;
    return Rect.fromLTWH(x, y, width, height);
  }

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
