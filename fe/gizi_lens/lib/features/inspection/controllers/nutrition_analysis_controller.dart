import 'package:flutter/material.dart';
import '../models/nutrition_analysis_model.dart';

class NutritionAnalysisController extends ChangeNotifier {
  final List<NutrientMetricModel> _metrics =
      NutrientMetricModel.getSampleMetrics();
  bool _isLoading = false;

  List<NutrientMetricModel> get metrics => List.unmodifiable(_metrics);
  bool get isLoading => _isLoading;

  Future<bool> proceedToStepConfirmation() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
