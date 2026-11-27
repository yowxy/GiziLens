import 'package:flutter/material.dart';
import '../../../core/services/backend_api_service.dart';
import '../../../core/services/inspection_session_service.dart';
import '../models/menu_recommendation_model.dart';
import '../models/nutrition_analysis_model.dart';

class NutritionAnalysisController extends ChangeNotifier {
  final _session = InspectionSessionService.instance;
  final List<NutrientMetricModel> _metrics;
  bool _isLoading = false;

  bool _isLoadingRecommendation = false;
  String? _recommendationError;
  MenuRecommendationModel? _recommendation;

  NutritionAnalysisController()
    : _metrics = NutrientMetricModel.fromComponents(
        InspectionSessionService.instance.components,
        InspectionSessionService.instance.targetAkg,
      );

  List<NutrientMetricModel> get metrics => List.unmodifiable(_metrics);
  bool get isLoading => _isLoading;
  String get targetGroupName => _session.targetAkg.groupName;

  MenuRecommendationModel? get recommendation => _recommendation;
  bool get isLoadingRecommendation => _isLoadingRecommendation;
  String? get recommendationError => _recommendationError;
  bool get hasRecommendation => _recommendation != null;

  String get targetSummary {
    final target = _session.targetAkg;
    return '${target.lunchCalories.toStringAsFixed(1)} kkal, '
        'Protein ${target.lunchProtein.toStringAsFixed(1)} g, '
        'Lemak ${target.lunchFat.toStringAsFixed(1)} g, '
        'Karbohidrat ${target.lunchCarbohydrate.toStringAsFixed(1)} g, '
        'Serat ${target.lunchFiber.toStringAsFixed(1)} g';
  }

  /// Ask the backend LLM what to add or swap to get closer to the AKG target.
  Future<void> loadRecommendation() async {
    if (_isLoadingRecommendation) return;

    _isLoadingRecommendation = true;
    _recommendationError = null;
    notifyListeners();

    final target = _session.targetAkg;
    final components = _session.components;
    final payload = <String, dynamic>{
      'targetGroup': target.groupName,
      'target': {
        'calories': target.lunchCalories,
        'protein': target.lunchProtein,
        'fat': target.lunchFat,
        'carbohydrate': target.lunchCarbohydrate,
        'fiber': target.lunchFiber,
      },
      'current': {
        'calories': components.fold<double>(0, (sum, c) => sum + c.calories),
        'protein': components.fold<double>(0, (sum, c) => sum + c.protein),
        'fat': components.fold<double>(0, (sum, c) => sum + c.fat),
        'carbohydrate': components.fold<double>(
          0,
          (sum, c) => sum + c.carbohydrate,
        ),
        'fiber': components.fold<double>(0, (sum, c) => sum + c.fiber),
      },
      'components': [
        for (final item in components)
          {
            'name': item.name,
            'category': item.category,
            'gram': item.estimatedGram,
            'calories': item.calories,
            'protein': item.protein,
            'fat': item.fat,
            'carbohydrate': item.carbohydrate,
            'fiber': item.fiber,
          },
      ],
      'notes': _session.notes,
    };

    try {
      final response = await BackendApiService.instance
          .requestMenuRecommendation(payload);
      if (response == null) {
        _recommendationError =
            'Rekomendasi belum bisa dimuat. Periksa koneksi lalu coba lagi.';
      } else {
        final model = MenuRecommendationModel.fromJson(response);
        if (model.isEmpty) {
          _recommendationError =
              'AI belum memberi rekomendasi untuk ompreng ini. Coba lagi.';
        } else {
          _recommendation = model;
        }
      }
    } catch (error) {
      _recommendationError = 'Gagal memuat rekomendasi: $error';
    } finally {
      _isLoadingRecommendation = false;
      notifyListeners();
    }
  }

  Future<bool> proceedToStepConfirmation() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
