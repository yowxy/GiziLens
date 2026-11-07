import 'package:flutter/material.dart';

class ScanOmprengController extends ChangeNotifier {
  bool _isFlashOn = false;
  bool _isAnalyzing = false;
  bool _isLightingOk = true;
  bool _isWholeTrayVisible = true;
  bool _isCameraFocused = true;
  bool _isWithinFrame = true;
  bool _showAiBoundingBoxes = true;

  bool get isFlashOn => _isFlashOn;
  bool get isAnalyzing => _isAnalyzing;
  bool get isLightingOk => _isLightingOk;
  bool get isWholeTrayVisible => _isWholeTrayVisible;
  bool get isCameraFocused => _isCameraFocused;
  bool get isWithinFrame => _isWithinFrame;
  bool get showAiBoundingBoxes => _showAiBoundingBoxes;

  void toggleFlash() {
    _isFlashOn = !_isFlashOn;
    notifyListeners();
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

  Future<bool> capturePhoto() async {
    _isAnalyzing = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));
    _isAnalyzing = false;
    notifyListeners();
    return true;
  }
}
