/// Menu suggestions produced by the backend LLM for the current tray.
class RecommendedMenuItem {
  const RecommendedMenuItem({
    required this.name,
    required this.category,
    required this.portion,
    required this.reason,
    required this.estimatedGram,
  });

  final String name;
  final String category;
  final String portion;
  final String reason;
  final double estimatedGram;

  factory RecommendedMenuItem.fromJson(Map<String, dynamic> json) {
    return RecommendedMenuItem(
      name: (json['name'] ?? '').toString().trim(),
      category: (json['category'] ?? 'Lainnya').toString().trim(),
      portion: (json['portion'] ?? '').toString().trim(),
      reason: (json['reason'] ?? '').toString().trim(),
      estimatedGram: _toDouble(json['estimatedGram']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class MenuRecommendationModel {
  const MenuRecommendationModel({
    required this.summary,
    required this.items,
    required this.tips,
  });

  final String summary;
  final List<RecommendedMenuItem> items;
  final List<String> tips;

  bool get isEmpty => summary.isEmpty && items.isEmpty && tips.isEmpty;

  factory MenuRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawTips = json['tips'];
    return MenuRecommendationModel(
      summary: (json['summary'] ?? '').toString().trim(),
      items: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(RecommendedMenuItem.fromJson)
                .where((item) => item.name.isNotEmpty)
                .toList(growable: false)
          : const [],
      tips: rawTips is List
          ? rawTips
                .map((tip) => tip.toString().trim())
                .where((tip) => tip.isNotEmpty)
                .toList(growable: false)
          : const [],
    );
  }
}
