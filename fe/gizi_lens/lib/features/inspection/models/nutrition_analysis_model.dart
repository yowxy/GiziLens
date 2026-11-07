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
}
