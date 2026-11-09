import 'package:flutter/material.dart';
import '../models/inspection_session.dart';
import '../models/nutrition_analysis_model.dart';

class NutritionAnalysisController extends ChangeNotifier {
  final target = InspectionSession.instance.targetAkg;
  final List<NutrientMetricModel> _metrics;
  bool _isLoading = false;

  NutritionAnalysisController()
    : _metrics = NutrientMetricModel.fromComponents(
        InspectionSession.instance.components,
        InspectionSession.instance.targetAkg,
      );

  List<NutrientMetricModel> get metrics => List.unmodifiable(_metrics);
  bool get isLoading => _isLoading;
  String get targetGroupName => target.groupName;
  String get targetSummary =>
      '${target.lunchCalories.toStringAsFixed(1)} kkal, '
      'Protein ${target.lunchProtein.toStringAsFixed(1)} g, '
      'Lemak ${target.lunchFat.toStringAsFixed(1)} g, '
      'Karbohidrat ${target.lunchCarbohydrate.toStringAsFixed(1)} g, '
      'Serat ${target.lunchFiber.toStringAsFixed(1)} g';

  Future<bool> proceedToStepConfirmation() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
