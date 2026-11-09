import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/inspection_session_service.dart';
import '../models/batch_info_model.dart';
import '../models/target_akg_model.dart';
import '../models/inspection_session.dart';

/// Controller handling operational batch input and state validation.
class MenuInspectionController extends ChangeNotifier {
  final String batchCode;
  final String sppgUnit;

  late TargetAkgModel _selectedTargetAkg;
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  MenuInspectionController({
    this.batchCode = AppStrings.defaultBatchCode,
    this.sppgUnit = AppStrings.defaultSppgUnit,
    TargetAkgModel? initialTargetAkg,
    String? initialSchool,
    String? initialNotes,
  }) {
    _selectedTargetAkg = initialTargetAkg ?? TargetAkgModel.standardPresets[1];
    schoolController.text =
        initialSchool ?? AppStrings.defaultSchoolDestination;
    notesController.text = initialNotes ?? AppStrings.defaultInspectionNotes;
  }

  TargetAkgModel get selectedTargetAkg => _selectedTargetAkg;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void selectTargetAkg(TargetAkgModel model) {
    if (_selectedTargetAkg != model) {
      _selectedTargetAkg = model;
      notifyListeners();
    }
  }

  void setSchoolDestination(String destination) {
    schoolController.text = destination;
    notifyListeners();
  }

  bool get isValid {
    return schoolController.text.trim().isNotEmpty;
  }

  BatchInfoModel getBatchData() {
    return BatchInfoModel(
      batchCode: batchCode,
      targetAkg: _selectedTargetAkg,
      sppgUnit: sppgUnit,
      schoolDestination: schoolController.text.trim(),
      notes: notesController.text.trim(),
    );
  }

  Future<bool> proceedToStep2() async {
    if (!isValid) {
      _errorMessage = 'Tujuan distribusi atau sekolah wajib diisi.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      InspectionSessionService.instance.updateBatchConfig(
        batchCode: batchCode,
        sppgUnit: sppgUnit,
        targetAkg: _selectedTargetAkg,
        schoolDestination: schoolController.text.trim(),
        notes: notesController.text.trim(),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      InspectionSession.instance.targetAkg = _selectedTargetAkg;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal menyimpan konfigurasi batch.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    schoolController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
