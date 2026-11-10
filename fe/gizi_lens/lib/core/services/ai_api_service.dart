import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../features/inspection/models/target_akg_model.dart';

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

class AiApiService {
  static const _model = 'gemini/gemini-3.5-flash';

  String get _apiKey => dotenv.env['SUMOPOD_API_KEY'] ?? '';
  String get _baseUrl =>
      dotenv.env['SUMOPOD_API_BASE_URL'] ?? 'https://ai.sumopod.com/v1';

  Future<List<ApiFoodItem>> analyzeImage(
    Uint8List imageBytes, {
    required TargetAkgModel target,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'API key AI belum diatur. Isi SUMOPOD_API_KEY di file .env.',
      );
    }

    final response = await http
        .post(
          Uri.parse(
            '${_baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions',
          ),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'temperature': 0.1,
            'max_tokens': 4096,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': _userPrompt(target)},
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url':
                          'data:image/jpeg;base64,${base64Encode(imageBytes)}',
                    },
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'API AI gagal (${response.statusCode}): ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = payload['choices'] as List<dynamic>?;
    final choice = choices == null || choices.isEmpty
        ? null
        : choices.first as Map<String, dynamic>;
    final message = choice?['message'] as Map<String, dynamic>?;
    final jsonText = _contentToJsonText(message?['content']);
    if (jsonText.isEmpty) {
      throw StateError(
        'AI tidak mengembalikan hasil (finish_reason: ${choice?['finish_reason']}). Coba analisis ulang.',
      );
    }
    final result = jsonDecode(jsonText) as Map<String, dynamic>;
    final items = result['items'] as List<dynamic>? ?? const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(_parseItem)
        .where((item) => item.name.isNotEmpty)
        .take(5)
        .toList(growable: false);
  }

  ApiFoodItem _parseItem(Map<String, dynamic> item) {
    final nutrition = item['nutrition'] as Map<String, dynamic>? ?? const {};
    return ApiFoodItem(
      name: _string(item['name']),
      category: _string(item['category'], fallback: 'Lainnya'),
      estimatedGram: _number(item['estimatedGram']).round().clamp(1, 2000),
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
    if (value is! List || value.length != 4) return null;
    final x = _number(value[0]).clamp(0.0, 1.0);
    final y = _number(value[1]).clamp(0.0, 1.0);
    final width = _number(value[2]).clamp(0.0, 1.0 - x);
    final height = _number(value[3]).clamp(0.0, 1.0 - y);
    if (width <= 0 || height <= 0) return null;
    return Rect.fromLTWH(x, y, width, height);
  }

  String _contentToJsonText(dynamic content) {
    if (content is String) return _stripMarkdownFence(content);
    if (content is List) {
      final text = content
          .whereType<Map<String, dynamic>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join();
      return _stripMarkdownFence(text);
    }
    throw const FormatException('Respons API AI tidak berisi JSON.');
  }

  String _stripMarkdownFence(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('```')) {
      return trimmed
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '')
          .trim();
    }
    return trimmed;
  }

  String _string(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _userPrompt(TargetAkgModel target) =>
      '''Analisis foto baki makanan ini.
Target penerima: ${target.groupName}.
Target makan siang berdasarkan AKG Indonesia 2019: ${target.lunchCalories.toStringAsFixed(1)} kkal, protein ${target.lunchProtein.toStringAsFixed(1)} g, lemak ${target.lunchFat.toStringAsFixed(1)} g, karbohidrat ${target.lunchCarbohydrate.toStringAsFixed(1)} g, serat ${target.lunchFiber.toStringAsFixed(1)} g.

Kembalikan hanya JSON valid dengan bentuk:
{"items":[{"name":"...","category":"Pokok|Lauk|Sayur|Buah|Minuman|Lainnya","estimatedGram":0,"confidence":0.0,"bbox":[0,0,0,0],"nutrition":{"calories":0,"protein":0,"fat":0,"carbohydrate":0,"fiber":0}}],"summary":"...","akgAssessment":"..."}

bbox adalah [x, y, lebar, tinggi] dalam nilai 0 sampai 1 relatif terhadap seluruh foto, dengan titik (0,0) di pojok kiri atas, dan mengelilingi seluruh porsi makanan tersebut.

Ambil hanya makanan yang benar-benar terlihat. Jangan mengarang makanan yang tertutup atau tidak jelas. Gunakan estimasi gram dan nutrisi per porsi yang wajar, tandai confidence 0 sampai 1, dan jelaskan kesesuaian total menu terhadap target AKG 2019 di summary atau akgAssessment. Jika foto tidak jelas, tetap kembalikan items kosong dan jelaskan alasannya.''';

  static const _systemPrompt =
      'Kamu adalah analis gizi makanan Indonesia. Jawab dalam Bahasa Indonesia. Jangan memberikan markdown, komentar, atau teks di luar JSON yang diminta. Nilai nutrisi adalah estimasi, bukan diagnosis medis.';
}
