/// Data model representing target AKG nutrition requirements per recipient group.
///
/// Every value is 30% of the daily AKG 2019 figure for that age group, matching
/// the lower bound of the MBG guideline (makan siang = 30–35% AKG). Fiber uses
/// the meal-level reference of 14 g per 1000 kkal, which is what a single plate
/// can realistically deliver; 30% of the *daily* fiber target is unreachable in
/// one meal because Indonesian menus are fiber-poor by nature.
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
      calories: 495,
      proteinRange: '11–13g',
      lunchCalories: 495.0,
      lunchProtein: 12.0,
      lunchFat: 16.5,
      lunchCarbohydrate: 75.0,
      lunchFiber: 7.0,
    ),
    TargetAkgModel(
      groupName: 'SD Kelas 4 – 6 (10 – 12 Tahun)',
      calories: 585,
      proteinRange: '14–16g',
      lunchCalories: 585.0,
      lunchProtein: 15.0,
      lunchFat: 19.5,
      lunchCarbohydrate: 87.0,
      lunchFiber: 8.0,
    ),
    TargetAkgModel(
      groupName: 'SMP (13 – 15 Tahun)',
      calories: 669,
      proteinRange: '18–22g',
      lunchCalories: 669.0,
      lunchProtein: 20.25,
      lunchFat: 22.5,
      lunchCarbohydrate: 97.5,
      lunchFiber: 9.0,
    ),
    TargetAkgModel(
      groupName: 'SMA / SMK (16 – 18 Tahun)',
      calories: 780,
      proteinRange: '20–25g',
      lunchCalories: 780.0,
      lunchProtein: 22.5,
      lunchFat: 25.5,
      lunchCarbohydrate: 117.0,
      lunchFiber: 11.0,
    ),
  ];
}
