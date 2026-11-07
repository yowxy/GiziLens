/// Data model representing target AKG nutrition requirements per recipient group.
class TargetAkgModel {
  final String groupName;
  final int calories;
  final String proteinRange;

  const TargetAkgModel({
    required this.groupName,
    required this.calories,
    required this.proteinRange,
  });

  String get formattedSummary => '$calories kkal • Protein $proteinRange';

  static const List<TargetAkgModel> standardPresets = [
    TargetAkgModel(
      groupName: 'SD Kelas 1 – 3 (7 – 9 Tahun)',
      calories: 450,
      proteinRange: '14–18g',
    ),
    TargetAkgModel(
      groupName: 'SD Kelas 4 – 6 (10 – 12 Tahun)',
      calories: 620,
      proteinRange: '18–22g',
    ),
    TargetAkgModel(
      groupName: 'SMP (13 – 15 Tahun)',
      calories: 700,
      proteinRange: '22–26g',
    ),
    TargetAkgModel(
      groupName: 'SMA / SMK (16 – 18 Tahun)',
      calories: 780,
      proteinRange: '25–30g',
    ),
    TargetAkgModel(
      groupName: 'Ibu Hamil & Menyusui',
      calories: 800,
      proteinRange: '30–35g',
    ),
  ];
}
