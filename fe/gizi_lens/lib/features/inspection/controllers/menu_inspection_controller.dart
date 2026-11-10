import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/inspection_session_service.dart';
import '../../../core/services/user_session_service.dart';
import '../models/batch_info_model.dart';
import '../models/target_akg_model.dart';

/// Controller handling operational batch input and state validation.
class MenuInspectionController extends ChangeNotifier {
  String _batchCode = '';
  final String sppgUnit;

  late TargetAkgModel _selectedTargetAkg;
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  MenuInspectionController({
    TargetAkgModel? initialTargetAkg,
    String? initialSchool,
    String? initialNotes,
  }) : sppgUnit = UserSessionService.instance.account.unitOperational {
    _selectedTargetAkg = initialTargetAkg ?? TargetAkgModel.standardPresets[1];
    schoolController.text =
        initialSchool ?? AppStrings.defaultSchoolDestination;
    notesController.text = initialNotes ?? AppStrings.defaultInspectionNotes;
  }

  TargetAkgModel get selectedTargetAkg => _selectedTargetAkg;
  String get batchCode => _batchCode;
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

  Future<void> prepareBatchCode() async {
    final inspections = await FirestoreService.instance.getInspections(limit: 500);
    _batchCode = nextBatchCode(inspections, DateTime.now().year);
    notifyListeners();
  }

  static String nextBatchCode(List<Map<String, dynamic>> inspections, int year) {
    final prefix = 'MBG-$year-';
    var lastSequence = 0;
    for (final inspection in inspections) {
      final code = inspection['batchCode'] as String? ?? '';
      if (!code.startsWith(prefix)) continue;
      final sequence = int.tryParse(code.substring(prefix.length));
      if (sequence != null && sequence > lastSequence) lastSequence = sequence;
    }
    return '$prefix${(lastSequence + 1).toString().padLeft(3, '0')}';
  }

  bool get isValid {
    return schoolController.text.trim().isNotEmpty;
  }

  BatchInfoModel getBatchData() {
    return BatchInfoModel(
      batchCode: _batchCode,
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

    if (_batchCode.isEmpty) {
      _errorMessage = 'Kode batch sedang disiapkan, coba lagi sebentar.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      InspectionSessionService.instance.updateBatchConfig(
        batchCode: _batchCode,
        sppgUnit: sppgUnit,
        targetAkg: _selectedTargetAkg,
        schoolDestination: schoolController.text.trim(),
        notes: notesController.text.trim(),
      );
      await Future.delayed(const Duration(milliseconds: 500));
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
