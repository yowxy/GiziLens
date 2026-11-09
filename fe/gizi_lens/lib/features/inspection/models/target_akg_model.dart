/// Data model representing target AKG nutrition requirements per recipient group.
class TargetAkgModel {
  final String groupName;
  final int calories;
  final String proteinRange;
  final double lunchCalories;
  final double lunchProtein;
  final double lunchFat;
  final double lunchCarbohydrate;
  final double lunchFiber;

  const TargetAkgModel({
    required this.groupName,
    required this.calories,
    required this.proteinRange,
    required this.lunchCalories,
    required this.lunchProtein,
    required this.lunchFat,
    required this.lunchCarbohydrate,
    required this.lunchFiber,
  });

  String get formattedSummary => '$calories kkal • Protein $proteinRange';

  static const List<TargetAkgModel> standardPresets = [
    TargetAkgModel(
      groupName: 'SD Kelas 1 – 3 (7 – 9 Tahun)',
      calories: 450,
      proteinRange: '14–18g',
      lunchCalories: 536.25,
      lunchProtein: 13.0,
      lunchFat: 17.875,
      lunchCarbohydrate: 81.25,
      lunchFiber: 7.475,
    ),
    TargetAkgModel(
      groupName: 'SD Kelas 4 – 6 (10 – 12 Tahun)',
      calories: 620,
      proteinRange: '18–22g',
      lunchCalories: 633.75,
      lunchProtein: 16.25,
      lunchFat: 21.125,
      lunchCarbohydrate: 94.25,
      lunchFiber: 8.9375,
    ),
    TargetAkgModel(
      groupName: 'SMP (13 – 15 Tahun)',
      calories: 700,
      proteinRange: '22–26g',
      lunchCalories: 724.375,
      lunchProtein: 21.9375,
      lunchFat: 24.375,
      lunchCarbohydrate: 105.625,
      lunchFiber: 10.2375,
    ),
    TargetAkgModel(
      groupName: 'SMA / SMK (16 – 18 Tahun)',
      calories: 780,
      proteinRange: '25–30g',
      lunchCalories: 845.0,
      lunchProtein: 24.375,
      lunchFat: 27.625,
      lunchCarbohydrate: 126.75,
      lunchFiber: 11.8625,
    ),
    TargetAkgModel(
      groupName: 'Ibu Hamil & Menyusui',
      calories: 800,
      proteinRange: '30–35g',
      lunchCalories: 780.0,
      lunchProtein: 29.25,
      lunchFat: 25.35,
      lunchCarbohydrate: 117.0,
      lunchFiber: 8.125,
    ),
  ];
}
