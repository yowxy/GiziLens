import 'food_component_model.dart';
import 'target_akg_model.dart';

class NutrientMetricModel {
  final String name;
  final double currentValue;
  final double targetValue;
  final String unit;
  final int percentageOfTarget;
  final String statusLabel;
  final bool isSurplus;
  final bool isCompliant;

  const NutrientMetricModel({
    required this.name,
    required this.currentValue,
    required this.targetValue,
    required this.unit,
    required this.percentageOfTarget,
    required this.statusLabel,
    this.isSurplus = false,
    this.isCompliant = true,
  });

  static List<NutrientMetricModel> fromComponents(
    List<FoodComponentModel> components,
    TargetAkgModel target,
  ) {
    final totals = [
      components.fold<double>(0, (sum, item) => sum + item.calories),
      components.fold<double>(0, (sum, item) => sum + item.protein),
      components.fold<double>(0, (sum, item) => sum + item.fat),
      components.fold<double>(0, (sum, item) => sum + item.carbohydrate),
      components.fold<double>(0, (sum, item) => sum + item.fiber),
    ];
    final targets = [
      target.lunchCalories,
      target.lunchProtein,
      target.lunchFat,
      target.lunchCarbohydrate,
      target.lunchFiber,
    ];
    final names = [
      'Energi Total',
      'Protein Hewani & Nabati',
      'Lemak Sehat',
      'Karbohidrat Kompleks',
      'Serat',
    ];
    final units = ['kkal', 'g', 'g', 'g', 'g'];
    return List.generate(names.length, (index) {
      final percentage = targets[index] == 0
          ? 0
          : (totals[index] / targets[index] * 100).round();
      final isSurplus = percentage > 110;
      final isBelow = percentage < 90;
      return NutrientMetricModel(
        name: names[index],
        currentValue: totals[index],
        targetValue: targets[index],
        unit: units[index],
        percentageOfTarget: percentage,
        statusLabel: isSurplus
            ? 'Di atas Target'
            : isBelow
            ? 'Di bawah Target'
            : 'Sesuai Rentang Toleransi',
        isSurplus: isSurplus,
        isCompliant: !isSurplus && !isBelow,
      );
    });
  }
}
