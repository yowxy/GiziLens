import 'package:flutter/material.dart';
import '../../../core/services/inspection_session_service.dart';
import '../models/food_component_model.dart';
import '../models/inspection_session.dart';

class ComponentDetectionController extends ChangeNotifier {
  final List<FoodComponentModel> _components = List<FoodComponentModel>.from(
    InspectionSession.instance.components,
  );
  bool _isLoading = false;

  List<FoodComponentModel> get components =>
      InspectionSessionService.instance.components;
  bool get isLoading => _isLoading;
  int get totalIngredients => components.length;

  ComponentDetectionController() {
    InspectionSessionService.instance.addListener(_onSessionUpdated);
  }

  void _onSessionUpdated() {
    notifyListeners();
  }

  void updateComponentGram(String id, int newGram) {
    final index = _components.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = _components[index];
      _components[index] = FoodComponentModel(
        id: old.id,
        name: old.name,
        estimatedGram: newGram,
        compartmentNumber: old.compartmentNumber,
        category: old.category,
        confidencePercentage: old.confidencePercentage,
        isVerified: true,
        complianceStatus: old.complianceStatus,
        iconData: old.iconData,
        calories: old.calories * newGram / old.estimatedGram,
        protein: old.protein * newGram / old.estimatedGram,
        fat: old.fat * newGram / old.estimatedGram,
        carbohydrate: old.carbohydrate * newGram / old.estimatedGram,
        fiber: old.fiber * newGram / old.estimatedGram,
      );
      InspectionSession.instance.components = List<FoodComponentModel>.from(
        _components,
      );
      notifyListeners();
    }
  }

  Future<bool> proceedToStep4() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    InspectionSessionService.instance.removeListener(_onSessionUpdated);
    super.dispose();
  }
}
