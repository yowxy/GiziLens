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

  static List<NutrientMetricModel> getSampleMetrics() {
    return const [
      NutrientMetricModel(
        name: 'Energi Total',
        currentValue: 701,
        targetValue: 762.5,
        unit: 'kkal',
        percentageOfTarget: 92,
        statusLabel: 'Sesuai Standar',
        isCompliant: true,
      ),
      NutrientMetricModel(
        name: 'Protein Hewani & Nabati',
        currentValue: 23.1,
        targetValue: 24.0,
        unit: 'g',
        percentageOfTarget: 96,
        statusLabel: 'Sesuai Standar',
        isCompliant: true,
      ),
      NutrientMetricModel(
        name: 'Lemak Sehat',
        currentValue: 28.2,
        targetValue: 25.0,
        unit: 'g',
        percentageOfTarget: 113,
        statusLabel: 'Di atas Target',
        isSurplus: true,
        isCompliant: false,
      ),
      NutrientMetricModel(
        name: 'Karbohidrat Kompleks',
        currentValue: 89.0,
        targetValue: 110.0,
        unit: 'g',
        percentageOfTarget: 81,
        statusLabel: 'Sesuai Rentang Toleransi',
        isCompliant: true,
      ),
    ];
  }

  static List<NutrientMetricModel> fromComponents(
    List<FoodComponentModel> components,
    TargetAkgModel target,
  ) {
    final totals = [
      components.fold<double>(0, (sum, item) => sum + item.calories),
      components.fold<double>(0, (sum, item) => sum + item.protein),
      components.fold<double>(0, (sum, item) => sum + item.fat),
      components.fold<double>(0, (sum, item) => sum + item.carbohydrate),
    ];
    final targets = [
      target.lunchCalories,
      target.lunchProtein,
      target.lunchFat,
      target.lunchCarbohydrate,
    ];
    final names = [
      'Energi Total',
      'Protein Hewani & Nabati',
      'Lemak Sehat',
      'Karbohidrat Kompleks',
    ];
    final units = ['kkal', 'g', 'g', 'g'];
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
