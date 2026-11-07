import 'target_akg_model.dart';

/// Data class representing operational batch configuration for menu inspection.
class BatchInfoModel {
  final String batchCode;
  final TargetAkgModel targetAkg;
  final String sppgUnit;
  final String schoolDestination;
  final String notes;

  const BatchInfoModel({
    required this.batchCode,
    required this.targetAkg,
    required this.sppgUnit,
    required this.schoolDestination,
    required this.notes,
  });

  BatchInfoModel copyWith({
    String? batchCode,
    TargetAkgModel? targetAkg,
    String? sppgUnit,
    String? schoolDestination,
    String? notes,
  }) {
    return BatchInfoModel(
      batchCode: batchCode ?? this.batchCode,
      targetAkg: targetAkg ?? this.targetAkg,
      sppgUnit: sppgUnit ?? this.sppgUnit,
      schoolDestination: schoolDestination ?? this.schoolDestination,
      notes: notes ?? this.notes,
    );
  }
}
