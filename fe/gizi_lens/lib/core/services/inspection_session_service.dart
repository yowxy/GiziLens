import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../../features/inspection/models/food_component_model.dart';
import '../../features/inspection/models/target_akg_model.dart';

/// Central singleton service maintaining live operational inspection session state,
/// seamlessly bridging MenuInspection, ScanOmpreng, ComponentDetection,
/// NutritionAnalysis, and AuditConfirmation.
class InspectionSessionService extends ChangeNotifier {
  InspectionSessionService._() {
    reset();
  }

  static final InspectionSessionService instance = InspectionSessionService._();

  String _batchCode = AppStrings.defaultSamplingBatchCode;
  String _sppgUnit = AppStrings.defaultSppgUnit;
  TargetAkgModel _targetAkg = TargetAkgModel.standardPresets[1];
  String _schoolDestination = AppStrings.defaultSamplingSchool;
  String _notes = AppStrings.defaultInspectionNotes;
  List<FoodComponentModel> _components = [];
  Uint8List? _capturedPhoto;
  double _capturedPhotoAspectRatio = 1;

  String get batchCode => _batchCode;
  String get sppgUnit => _sppgUnit;
  TargetAkgModel get targetAkg => _targetAkg;
  String get schoolDestination => _schoolDestination;
  String get notes => _notes;
  List<FoodComponentModel> get components => List.unmodifiable(_components);
  Uint8List? get capturedPhoto => _capturedPhoto;
  double get capturedPhotoAspectRatio => _capturedPhotoAspectRatio;

  set components(List<FoodComponentModel> value) {
    _components = List<FoodComponentModel>.from(value);
    notifyListeners();
  }

  void setCapturedPhoto(Uint8List bytes, double aspectRatio) {
    _capturedPhoto = bytes;
    _capturedPhotoAspectRatio = aspectRatio;
    notifyListeners();
  }

  int get totalNetWeight =>
      _components.fold<int>(0, (sum, item) => sum + item.estimatedGram);

  void reset() {
    _batchCode = AppStrings.defaultSamplingBatchCode;
    _sppgUnit = AppStrings.defaultSppgUnit;
    _targetAkg = TargetAkgModel.standardPresets[1];
    _schoolDestination = AppStrings.defaultSamplingSchool;
    _notes = AppStrings.defaultInspectionNotes;
    _components = [];
    _capturedPhoto = null;
    _capturedPhotoAspectRatio = 1;
    notifyListeners();
  }

  void updateBatchConfig({
    String? batchCode,
    String? sppgUnit,
    TargetAkgModel? targetAkg,
    String? schoolDestination,
    String? notes,
  }) {
    if (batchCode != null && batchCode.trim().isNotEmpty) {
      _batchCode = batchCode.trim();
    }
    if (sppgUnit != null && sppgUnit.trim().isNotEmpty) {
      _sppgUnit = sppgUnit.trim();
    }
    if (targetAkg != null) {
      _targetAkg = targetAkg;
    }
    if (schoolDestination != null && schoolDestination.trim().isNotEmpty) {
      _schoolDestination = schoolDestination.trim();
    }
    if (notes != null) {
      _notes = notes.trim();
    }
    notifyListeners();
  }

  void updateComponent({
    required String id,
    String? newName,
    int? newGram,
    String? category,
    String? complianceStatus,
  }) {
    final index = _components.indexWhere((c) => c.id == id);
    if (index != -1) {
      final old = _components[index];
      final gram = newGram ?? old.estimatedGram;
      final scale = old.estimatedGram == 0 ? 1.0 : gram / old.estimatedGram;
      _components[index] = FoodComponentModel(
        id: old.id,
        name: (newName != null && newName.trim().isNotEmpty) ? newName.trim() : old.name,
        estimatedGram: gram,
        compartmentNumber: old.compartmentNumber,
        category: (category != null && category.trim().isNotEmpty) ? category.trim() : old.category,
        confidencePercentage: old.confidencePercentage,
        isVerified: true,
        complianceStatus: complianceStatus ?? old.complianceStatus,
        iconData: old.iconData,
        calories: old.calories * scale,
        protein: old.protein * scale,
        fat: old.fat * scale,
        carbohydrate: old.carbohydrate * scale,
        fiber: old.fiber * scale,
        boundingBox: old.boundingBox,
      );
      notifyListeners();
    }
  }
}
