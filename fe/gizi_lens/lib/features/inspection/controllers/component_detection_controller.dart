import 'package:flutter/material.dart';
import '../../../core/services/inspection_session_service.dart';
import '../models/food_component_model.dart';

class ComponentDetectionController extends ChangeNotifier {
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

  void updateComponent({
    required String id,
    String? newName,
    int? newGram,
    String? category,
    String? complianceStatus,
  }) {
    InspectionSessionService.instance.updateComponent(
      id: id,
      newName: newName,
      newGram: newGram,
      category: category,
      complianceStatus: complianceStatus,
    );
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
