import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/detection_api_service.dart';
import '../../../core/services/inspection_session_service.dart';
import '../models/food_component_model.dart';

class ScanOmprengController extends ChangeNotifier {
  final DetectionApiService _detectionApi = DetectionApiService();
  bool _isFlashOn = false;
  bool _isAnalyzing = false;
  bool _isModelReady = false;
  String? _errorMessage;
  bool _isLightingOk = false;
  bool _isWholeTrayVisible = false;
  bool _isCameraFocused = false;
  bool _isWithinFrame = false;
  bool _showAiBoundingBoxes = true;

  bool get isFlashOn => _isFlashOn;
  bool get isAnalyzing => _isAnalyzing;
  bool get isModelReady => _isModelReady;
  String? get errorMessage => _errorMessage;
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
    // Detection runs entirely on the backend, so there is no on-device model
    // to load. Capture will surface any connectivity error.
    _isModelReady = true;
    _errorMessage = null;
    notifyListeners();
    return true;
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
      _errorMessage ??= 'Layanan deteksi belum siap. Tunggu sebentar.';
      notifyListeners();
      return false;
    }
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = Uint8List.fromList(await photo.readAsBytes());
      final result = await _detectionApi.analyzeImage(
        bytes,
        target: InspectionSessionService.instance.targetAkg,
      );
      if (result.items.isEmpty) {
        _errorMessage = 'Makanan belum terdeteksi. Ambil ulang foto ompreng.';
        return false;
      }

      final decoded = await decodeImageFromList(bytes);
      final aspectRatio = decoded.width / decoded.height;
      decoded.dispose();
      _saveApiComponents(result.items);
      InspectionSessionService.instance.setCapturedPhoto(bytes, aspectRatio);
      return true;
    } on TimeoutException {
      _errorMessage = 'Server belum merespons. Periksa koneksi lalu coba lagi.';
      return false;
    } on http.ClientException {
      _errorMessage =
          'Gagal terhubung ke server. Periksa koneksi lalu coba lagi.';
      return false;
    } on DetectionApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = 'Analisis citra gagal: $error';
      return false;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void _saveApiComponents(List<ApiFoodItem> items) {
    InspectionSessionService.instance.components = [
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
      boundingBox: item.boundingBox,
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
}
