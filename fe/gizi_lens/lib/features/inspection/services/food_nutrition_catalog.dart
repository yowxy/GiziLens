import 'package:flutter/material.dart';

import '../models/food_component_model.dart';

class FoodNutrition {
  final String displayName;
  final String category;
  final int defaultGram;
  final IconData icon;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbohydratePer100g;
  final double fiberPer100g;

  const FoodNutrition({
    required this.displayName,
    required this.category,
    required this.defaultGram,
    required this.icon,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbohydratePer100g,
    required this.fiberPer100g,
  });

  FoodComponentModel toComponent({
    required String id,
    required int compartmentNumber,
    required int confidencePercentage,
  }) {
    final factor = defaultGram / 100;
    return FoodComponentModel(
      id: id,
      name: displayName,
      estimatedGram: defaultGram,
      compartmentNumber: compartmentNumber,
      category: category,
      confidencePercentage: confidencePercentage,
      iconData: icon,
      calories: caloriesPer100g * factor,
      protein: proteinPer100g * factor,
      fat: fatPer100g * factor,
      carbohydrate: carbohydratePer100g * factor,
      fiber: fiberPer100g * factor,
    );
  }
}

class FoodNutritionCatalog {
  FoodNutritionCatalog._();

  static const _overrides = <String, FoodNutrition>{
    'nasi_putih': FoodNutrition(
      displayName: 'Nasi Putih',
      category: 'Pokok',
      defaultGram: 200,
      icon: Icons.rice_bowl_rounded,
      caloriesPer100g: 175,
      proteinPer100g: 3.2,
      fatPer100g: 0.3,
      carbohydratePer100g: 40.6,
      fiberPer100g: 0.4,
    ),
    'nasi_merah': FoodNutrition(
      displayName: 'Nasi Merah',
      category: 'Pokok',
      defaultGram: 200,
      icon: Icons.rice_bowl_rounded,
      caloriesPer100g: 149,
      proteinPer100g: 2.8,
      fatPer100g: 0.4,
      carbohydratePer100g: 32.5,
      fiberPer100g: 1.8,
    ),
    'nasi_kuning': FoodNutrition(
      displayName: 'Nasi Kuning',
      category: 'Pokok',
      defaultGram: 200,
      icon: Icons.rice_bowl_rounded,
      caloriesPer100g: 180,
      proteinPer100g: 3.0,
      fatPer100g: 3.0,
      carbohydratePer100g: 34.0,
      fiberPer100g: 0.8,
    ),
    'nasi_goreng': FoodNutrition(
      displayName: 'Nasi Goreng',
      category: 'Pokok',
      defaultGram: 200,
      icon: Icons.rice_bowl_rounded,
      caloriesPer100g: 193,
      proteinPer100g: 6.0,
      fatPer100g: 6.0,
      carbohydratePer100g: 29.0,
      fiberPer100g: 1.2,
    ),
    'mie_goreng': FoodNutrition(
      displayName: 'Mi Goreng',
      category: 'Pokok',
      defaultGram: 180,
      icon: Icons.ramen_dining_rounded,
      caloriesPer100g: 175,
      proteinPer100g: 5.0,
      fatPer100g: 5.5,
      carbohydratePer100g: 27.0,
      fiberPer100g: 1.5,
    ),
    'bihun': FoodNutrition(
      displayName: 'Bihun',
      category: 'Pokok',
      defaultGram: 180,
      icon: Icons.ramen_dining_rounded,
      caloriesPer100g: 109,
      proteinPer100g: 0.9,
      fatPer100g: 0.2,
      carbohydratePer100g: 25.0,
      fiberPer100g: 0.9,
    ),
    'kentang_rebus': FoodNutrition(
      displayName: 'Kentang Rebus',
      category: 'Pokok',
      defaultGram: 150,
      icon: Icons.restaurant_rounded,
      caloriesPer100g: 87,
      proteinPer100g: 1.9,
      fatPer100g: 0.1,
      carbohydratePer100g: 20.1,
      fiberPer100g: 1.8,
    ),
    'roti_tawar': FoodNutrition(
      displayName: 'Roti Tawar',
      category: 'Pokok',
      defaultGram: 60,
      icon: Icons.bakery_dining_rounded,
      caloriesPer100g: 248,
      proteinPer100g: 8.0,
      fatPer100g: 3.2,
      carbohydratePer100g: 49.0,
      fiberPer100g: 2.7,
    ),
    'ayam_goreng': FoodNutrition(
      displayName: 'Ayam Goreng',
      category: 'Lauk',
      defaultGram: 80,
      icon: Icons.restaurant_rounded,
      caloriesPer100g: 260,
      proteinPer100g: 25.0,
      fatPer100g: 17.0,
      carbohydratePer100g: 0,
      fiberPer100g: 0,
    ),
    'ayam_rebus': FoodNutrition(
      displayName: 'Ayam Rebus',
      category: 'Lauk',
      defaultGram: 80,
      icon: Icons.restaurant_rounded,
      caloriesPer100g: 165,
      proteinPer100g: 31.0,
      fatPer100g: 3.6,
      carbohydratePer100g: 0,
      fiberPer100g: 0,
    ),
    'ayam_bakar': FoodNutrition(
      displayName: 'Ayam Bakar',
      category: 'Lauk',
      defaultGram: 80,
      icon: Icons.restaurant_rounded,
      caloriesPer100g: 215,
      proteinPer100g: 27.0,
      fatPer100g: 10.0,
      carbohydratePer100g: 2.0,
      fiberPer100g: 0,
    ),
    'daging_sapi': FoodNutrition(
      displayName: 'Daging Sapi',
      category: 'Lauk',
      defaultGram: 75,
      icon: Icons.restaurant_rounded,
      caloriesPer100g: 217,
      proteinPer100g: 26.1,
      fatPer100g: 11.8,
      carbohydratePer100g: 0,
      fiberPer100g: 0,
    ),
    'ikan_goreng': FoodNutrition(
      displayName: 'Ikan Goreng',
      category: 'Lauk',
      defaultGram: 75,
      icon: Icons.set_meal_rounded,
      caloriesPer100g: 206,
      proteinPer100g: 22.0,
      fatPer100g: 12.0,
      carbohydratePer100g: 0,
      fiberPer100g: 0,
    ),
    'ikan_bakar': FoodNutrition(
      displayName: 'Ikan Bakar',
      category: 'Lauk',
      defaultGram: 75,
      icon: Icons.set_meal_rounded,
      caloriesPer100g: 160,
      proteinPer100g: 25.0,
      fatPer100g: 6.0,
      carbohydratePer100g: 0,
      fiberPer100g: 0,
    ),
    'telur_rebus': FoodNutrition(
      displayName: 'Telur Rebus',
      category: 'Lauk',
      defaultGram: 60,
      icon: Icons.egg_alt_outlined,
      caloriesPer100g: 154,
      proteinPer100g: 12.4,
      fatPer100g: 10.8,
      carbohydratePer100g: 0.7,
      fiberPer100g: 0,
    ),
    'telur_dadar': FoodNutrition(
      displayName: 'Telur Dadar',
      category: 'Lauk',
      defaultGram: 60,
      icon: Icons.egg_alt_outlined,
      caloriesPer100g: 196,
      proteinPer100g: 11.0,
      fatPer100g: 16.0,
      carbohydratePer100g: 1.5,
      fiberPer100g: 0,
    ),
    'tempe_goreng': FoodNutrition(
      displayName: 'Tempe',
      category: 'Lauk',
      defaultGram: 100,
      icon: Icons.restaurant_menu_rounded,
      caloriesPer100g: 201,
      proteinPer100g: 19.9,
      fatPer100g: 8.8,
      carbohydratePer100g: 13.5,
      fiberPer100g: 1.4,
    ),
    'tahu_goreng': FoodNutrition(
      displayName: 'Tahu Goreng',
      category: 'Lauk',
      defaultGram: 80,
      icon: Icons.restaurant_menu_rounded,
      caloriesPer100g: 271,
      proteinPer100g: 17.2,
      fatPer100g: 20.0,
      carbohydratePer100g: 8.9,
      fiberPer100g: 0.9,
    ),
    'udang': FoodNutrition(
      displayName: 'Udang',
      category: 'Lauk',
      defaultGram: 75,
      icon: Icons.set_meal_rounded,
      caloriesPer100g: 99,
      proteinPer100g: 20.3,
      fatPer100g: 1.1,
      carbohydratePer100g: 0.2,
      fiberPer100g: 0,
    ),
    'sayur_lain': FoodNutrition(
      displayName: 'Sayuran',
      category: 'Sayur',
      defaultGram: 75,
      icon: Icons.eco_outlined,
      caloriesPer100g: 35,
      proteinPer100g: 2.0,
      fatPer100g: 0.4,
      carbohydratePer100g: 6.0,
      fiberPer100g: 2.5,
    ),
    'bayam': FoodNutrition(
      displayName: 'Bayam',
      category: 'Sayur',
      defaultGram: 75,
      icon: Icons.eco_outlined,
      caloriesPer100g: 23,
      proteinPer100g: 2.9,
      fatPer100g: 0.4,
      carbohydratePer100g: 3.6,
      fiberPer100g: 2.2,
    ),
    'wortel': FoodNutrition(
      displayName: 'Wortel',
      category: 'Sayur',
      defaultGram: 75,
      icon: Icons.eco_outlined,
      caloriesPer100g: 41,
      proteinPer100g: 0.9,
      fatPer100g: 0.2,
      carbohydratePer100g: 9.6,
      fiberPer100g: 2.8,
    ),
    'tomat': FoodNutrition(
      displayName: 'Tomat',
      category: 'Sayur',
      defaultGram: 75,
      icon: Icons.eco_outlined,
      caloriesPer100g: 18,
      proteinPer100g: 0.9,
      fatPer100g: 0.2,
      carbohydratePer100g: 3.9,
      fiberPer100g: 1.2,
    ),
    'tumis_kangkung': FoodNutrition(
      displayName: 'Tumis Kangkung',
      category: 'Sayur',
      defaultGram: 100,
      icon: Icons.eco_outlined,
      caloriesPer100g: 72,
      proteinPer100g: 2.6,
      fatPer100g: 4.5,
      carbohydratePer100g: 6.0,
      fiberPer100g: 2.0,
    ),
    'pisang': FoodNutrition(
      displayName: 'Pisang',
      category: 'Buah',
      defaultGram: 100,
      icon: Icons.eco_outlined,
      caloriesPer100g: 89,
      proteinPer100g: 1.1,
      fatPer100g: 0.3,
      carbohydratePer100g: 22.8,
      fiberPer100g: 2.6,
    ),
    'jeruk': FoodNutrition(
      displayName: 'Jeruk',
      category: 'Buah',
      defaultGram: 120,
      icon: Icons.eco_outlined,
      caloriesPer100g: 47,
      proteinPer100g: 0.9,
      fatPer100g: 0.1,
      carbohydratePer100g: 11.8,
      fiberPer100g: 2.4,
    ),
    'apel': FoodNutrition(
      displayName: 'Apel',
      category: 'Buah',
      defaultGram: 100,
      icon: Icons.eco_outlined,
      caloriesPer100g: 52,
      proteinPer100g: 0.3,
      fatPer100g: 0.2,
      carbohydratePer100g: 13.8,
      fiberPer100g: 2.4,
    ),
    'pepaya': FoodNutrition(
      displayName: 'Pepaya',
      category: 'Buah',
      defaultGram: 100,
      icon: Icons.eco_outlined,
      caloriesPer100g: 43,
      proteinPer100g: 0.5,
      fatPer100g: 0.3,
      carbohydratePer100g: 10.8,
      fiberPer100g: 1.7,
    ),
    'mangga': FoodNutrition(
      displayName: 'Mangga',
      category: 'Buah',
      defaultGram: 100,
      icon: Icons.eco_outlined,
      caloriesPer100g: 60,
      proteinPer100g: 0.8,
      fatPer100g: 0.4,
      carbohydratePer100g: 15.0,
      fiberPer100g: 1.6,
    ),
    'susu_kotak': FoodNutrition(
      displayName: 'Susu Kotak',
      category: 'Susu',
      defaultGram: 115,
      icon: Icons.local_drink_rounded,
      caloriesPer100g: 61,
      proteinPer100g: 3.2,
      fatPer100g: 3.3,
      carbohydratePer100g: 4.8,
      fiberPer100g: 0,
    ),
    'susu_coklat': FoodNutrition(
      displayName: 'Susu Coklat',
      category: 'Susu',
      defaultGram: 115,
      icon: Icons.local_drink_rounded,
      caloriesPer100g: 78,
      proteinPer100g: 3.2,
      fatPer100g: 2.5,
      carbohydratePer100g: 10.5,
      fiberPer100g: 0.5,
    ),
    'susu_kedelai': FoodNutrition(
      displayName: 'Susu Kedelai',
      category: 'Susu',
      defaultGram: 115,
      icon: Icons.local_drink_rounded,
      caloriesPer100g: 54,
      proteinPer100g: 3.3,
      fatPer100g: 1.8,
      carbohydratePer100g: 6.3,
      fiberPer100g: 0.6,
    ),
    'yogurt': FoodNutrition(
      displayName: 'Yogurt',
      category: 'Susu',
      defaultGram: 100,
      icon: Icons.local_drink_rounded,
      caloriesPer100g: 61,
      proteinPer100g: 3.5,
      fatPer100g: 3.3,
      carbohydratePer100g: 4.7,
      fiberPer100g: 0,
    ),
  };

  static FoodNutrition? find(String className) {
    final normalized = className.toLowerCase().trim().replaceAll(' ', '_');
    if (normalized == 'ompreng' || normalized == 'sekat_ompreng') return null;
    final exact = _overrides[normalized];
    if (exact != null) return exact;

    if (normalized.contains('telur')) {
      return _profile(normalized, 'Lauk', 60, 154, 12.4, 10.8, 0.7, 0);
    }
    if (normalized.contains('tempe')) {
      return _profile(normalized, 'Lauk', 80, 201, 19.9, 8.8, 13.5, 1.4);
    }
    if (normalized.contains('tahu')) {
      return _profile(normalized, 'Lauk', 80, 144, 10.9, 8.7, 2.8, 0.4);
    }
    if (normalized.contains('ayam')) {
      return _profile(normalized, 'Lauk', 80, 190, 27, 8.5, 2, 0);
    }
    if (normalized.contains('ikan') ||
        normalized == 'lele_goreng' ||
        normalized == 'nila_goreng') {
      return _profile(normalized, 'Lauk', 75, 170, 23, 7.5, 1, 0);
    }
    if (normalized.contains('daging') ||
        normalized == 'rendang' ||
        normalized == 'empal') {
      return _profile(normalized, 'Lauk', 75, 220, 25, 13, 2, 0);
    }
    if (normalized.contains('udang') ||
        normalized == 'cumi' ||
        normalized == 'teri') {
      return _profile(normalized, 'Lauk', 75, 120, 21, 3, 1, 0);
    }
    if (_startsWithAny(normalized, const [
      'nasi',
      'mie',
      'bihun',
      'kwetiau',
      'makaroni',
      'kentang',
      'ubi',
      'singkong',
      'jagung',
      'talas',
      'roti',
      'oatmeal',
      'papeda',
      'lemper',
      'arem_arem',
      'getuk',
      'tiwul',
    ])) {
      return _profile(normalized, 'Pokok', 150, 170, 4, 2, 32, 2);
    }
    if (_startsWithAny(normalized, const [
      'sayur',
      'tumis',
      'urap',
      'pecel',
      'gado',
      'karedok',
      'salad',
      'lalapan',
      'wortel',
      'tomat',
      'timun',
      'selada',
      'kol',
      'bayam',
      'kangkung',
      'sawi',
      'pakcoy',
      'buncis',
      'tauge',
      'labu',
      'terong',
      'jamur',
      'paprika',
      'pare',
      'gambas',
      'okra',
      'rebung',
      'daun',
      'kemangi',
      'seledri',
      'lobak',
      'bit',
      'garlic',
    ])) {
      return _profile(normalized, 'Sayur', 75, 35, 2, 0.4, 6, 2.5);
    }
    if (_startsWithAny(normalized, const [
      'pisang',
      'jeruk',
      'apel',
      'pepaya',
      'semangka',
      'melon',
      'salak',
      'mangga',
      'nanas',
      'jambu',
      'anggur',
      'pir',
      'alpukat',
      'buah',
      'kiwi',
      'stroberi',
      'belimbing',
      'manggis',
      'rambutan',
      'lengkeng',
      'durian',
      'nangka',
      'cempedak',
      'sirsak',
      'markisa',
      'duku',
      'sawo',
      'kedondong',
      'delima',
      'blewah',
      'lemon',
      'kurma',
      'blueberry',
      'kelapa',
      'leci',
      'ceri',
    ])) {
      return _profile(normalized, 'Buah', 100, 60, 1, 0.3, 15, 2.5);
    }
    if (_startsWithAny(normalized, const [
      'susu',
      'yogurt',
      'keju',
      'kefir',
      'dadih',
      'dangke',
      'puding_susu',
      'es_krim',
    ])) {
      return _profile(normalized, 'Susu', 100, 100, 4, 4, 10, 0);
    }
    if (_startsWithAny(normalized, const [
      'tempe',
      'tahu',
      'oncom',
      'kacang',
      'edamame',
      'perkedel',
      'bakwan',
    ])) {
      return _profile(normalized, 'Lauk Nabati', 80, 170, 10, 7, 12, 3);
    }
    if (_startsWithAny(normalized, const [
      'sambal',
      'acar',
      'saus',
      'kecap',
      'kerupuk',
      'emping',
      'keripik',
      'rempeyek',
      'bawang_goreng',
      'cabai',
      'pelengkap',
    ])) {
      return _profile(normalized, 'Pelengkap', 20, 120, 2, 5, 16, 1);
    }
    if (_startsWithAny(normalized, const [
      'kue',
      'bolu',
      'biskuit',
      'pisang_goreng',
      'lumpia',
      'risoles',
      'pastel',
      'klepon',
      'onde',
      'burger',
    ])) {
      return _profile(normalized, 'Camilan', 60, 250, 5, 12, 35, 2);
    }
    return _profile(normalized, 'Lainnya', 75, 100, 4, 3, 14, 2);
  }

  static FoodNutrition _profile(
    String key,
    String category,
    int gram,
    double calories,
    double protein,
    double fat,
    double carbohydrate,
    double fiber,
  ) {
    return FoodNutrition(
      displayName: _displayName(key),
      category: category,
      defaultGram: gram,
      icon: category == 'Buah' || category == 'Sayur'
          ? Icons.eco_outlined
          : category == 'Susu'
          ? Icons.local_drink_rounded
          : Icons.restaurant_rounded,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      fatPer100g: fat,
      carbohydratePer100g: carbohydrate,
      fiberPer100g: fiber,
    );
  }

  static bool _startsWithAny(String value, List<String> prefixes) =>
      prefixes.any((prefix) => value.startsWith(prefix));

  static String _displayName(String value) => value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
