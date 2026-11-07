import 'package:flutter/material.dart';
import '../models/food_component_model.dart';

class ComponentDetectionController extends ChangeNotifier {
  final List<FoodComponentModel> _components =
      List<FoodComponentModel>.from(FoodComponentModel.getSampleComponents());
  bool _isLoading = false;

  List<FoodComponentModel> get components => List.unmodifiable(_components);
  bool get isLoading => _isLoading;
  int get totalIngredients => _components.length;

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
}
