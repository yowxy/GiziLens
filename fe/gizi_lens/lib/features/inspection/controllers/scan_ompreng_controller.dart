import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../../core/services/ai_api_service.dart';
import '../../../core/services/ai_mode.dart';
import '../../../core/services/ai_service.dart';
import '../models/food_component_model.dart';
import '../models/inspection_session.dart';
import '../services/food_nutrition_catalog.dart';

class ScanOmprengController extends ChangeNotifier {
  final AiService _aiService = AiService();
  final AiApiService _aiApiService = AiApiService();
  bool _isFlashOn = false;
  bool _isAnalyzing = false;
  bool _isModelReady = false;
  String? _errorMessage;
  List<DetectionResult> _detections = const [];
  bool _isLightingOk = true;
  bool _isWholeTrayVisible = true;
  bool _isCameraFocused = true;
  bool _isWithinFrame = true;
  bool _showAiBoundingBoxes = true;

  bool get isFlashOn => _isFlashOn;
  bool get isAnalyzing => _isAnalyzing;
  bool get isModelReady => _isModelReady;
  String? get errorMessage => _errorMessage;
  List<DetectionResult> get detections => List.unmodifiable(_detections);
  bool get isLightingOk => _isLightingOk;
  bool get isWholeTrayVisible => _isWholeTrayVisible;
  bool get isCameraFocused => _isCameraFocused;
  bool get isWithinFrame => _isWithinFrame;
  bool get showAiBoundingBoxes => _showAiBoundingBoxes;

  void toggleFlash() {
    _isFlashOn = !_isFlashOn;
    notifyListeners();
  }

  Future<bool> initializeModel() async {
    if (useApiAi) {
      _isModelReady = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    try {
      await _aiService.initModel();
      _isModelReady = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _isModelReady = false;
      _errorMessage = 'Model AI gagal dimuat: $error';
      notifyListeners();
      return false;
    }
  }

  void toggleBoundingBoxes() {
    _showAiBoundingBoxes = !_showAiBoundingBoxes;
    notifyListeners();
  }

  void setValidationStates({
    required bool lighting,
    required bool wholeTray,
    required bool focused,
    required bool withinFrame,
  }) {
    _isLightingOk = lighting;
    _isWholeTrayVisible = wholeTray;
    _isCameraFocused = focused;
    _isWithinFrame = withinFrame;
    notifyListeners();
  }

  Future<bool> capturePhoto(XFile photo) async {
    if (!_isModelReady) {
      _errorMessage ??= 'Model AI belum siap. Tunggu sampai pemuatan selesai.';
      notifyListeners();
      return false;
    }
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = await photo.readAsBytes();
      if (useApiAi) {
        final items = await _aiApiService.analyzeImage(
          Uint8List.fromList(bytes),
          target: InspectionSession.instance.targetAkg,
        );
        if (items.isEmpty) {
          throw const FormatException('Tidak ada menu makanan yang terbaca.');
        }
        _saveApiComponents(items);
      } else {
        _detections = await _aiService.detect(Uint8List.fromList(bytes));
        _saveDetectedComponents();
      }
      return true;
    } catch (error) {
      _errorMessage = 'Analisis citra gagal: $error';
      return false;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void _saveApiComponents(List<ApiFoodItem> items) {
    InspectionSession.instance.components = [
      for (var index = 0; index < items.length; index++)
        _toComponent(items[index], index + 1),
    ];
  }

  FoodComponentModel _toComponent(ApiFoodItem item, int compartmentNumber) {
    return FoodComponentModel(
      id: 'api_${item.name}_$compartmentNumber',
      name: item.name,
      estimatedGram: item.estimatedGram,
      compartmentNumber: compartmentNumber,
      category: item.category,
      confidencePercentage: (item.confidence * 100).round(),
      isVerified: false,
      complianceStatus: 'Estimasi AI',
      iconData: _iconForCategory(item.category),
      calories: item.calories,
      protein: item.protein,
      fat: item.fat,
      carbohydrate: item.carbohydrate,
      fiber: item.fiber,
    );
  }

  IconData _iconForCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('pokok')) return Icons.rice_bowl_rounded;
    if (normalized.contains('sayur')) return Icons.eco_outlined;
    if (normalized.contains('buah')) return Icons.apple_rounded;
    if (normalized.contains('minum')) return Icons.local_drink_rounded;
    return Icons.restaurant_rounded;
  }

  void _saveDetectedComponents() {
    final unique = <int, DetectionResult>{};
    for (final detection in _detections) {
      final current = unique[detection.classId];
      if (current == null || detection.confidence > current.confidence) {
        unique[detection.classId] = detection;
      }
    }

    final components = <FoodComponentModel>[];
    var compartment = 1;
    for (final detection in unique.values) {
      final nutrition = FoodNutritionCatalog.find(
        _aiService.labelFor(detection.classId),
      );
      if (nutrition == null) continue;
      components.add(
        nutrition.toComponent(
          id: 'detected_${detection.classId}',
          compartmentNumber: compartment++,
          confidencePercentage: (detection.confidence * 100).round().clamp(
            0,
            100,
          ),
        ),
      );
      if (components.length == 5) break;
    }
    if (components.isNotEmpty) {
      InspectionSession.instance.components = components;
    }
  }

  @override
  void dispose() {
    _aiService.close();
    super.dispose();
  }
}
