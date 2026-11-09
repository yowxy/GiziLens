import 'package:flutter/material.dart';

class FoodComponentModel {
  final String id;
  final String name;
  final int estimatedGram;
  final int compartmentNumber;
  final String category;
  final int confidencePercentage;
  final bool isVerified;
  final String complianceStatus;
  final IconData iconData;
  final double calories;
  final double protein;
  final double fat;
  final double carbohydrate;
  final double fiber;

  const FoodComponentModel({
    required this.id,
    required this.name,
    required this.estimatedGram,
    required this.compartmentNumber,
    required this.category,
    required this.confidencePercentage,
    this.isVerified = true,
    this.complianceStatus = 'Memenuhi AKG',
    this.iconData = Icons.restaurant_rounded,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbohydrate = 0,
    this.fiber = 0,
  });

  static List<FoodComponentModel> getSampleComponents() {
    return const [
      FoodComponentModel(
        id: 'comp_1',
        name: 'Nasi Kuning',
        estimatedGram: 200,
        compartmentNumber: 4,
        category: 'Pokok',
        confidencePercentage: 98,
        complianceStatus: 'Sesuai Standar',
        iconData: Icons.rice_bowl_rounded,
        calories: 360,
        protein: 6,
        fat: 6,
        carbohydrate: 68,
        fiber: 1.6,
      ),
      FoodComponentModel(
        id: 'comp_2',
        name: 'Telur Rebus',
        estimatedGram: 60,
        compartmentNumber: 3,
        category: 'Lauk',
        confidencePercentage: 98,
        complianceStatus: 'Memenuhi AKG',
        iconData: Icons.egg_alt_outlined,
        calories: 92.4,
        protein: 7.44,
        fat: 6.48,
        carbohydrate: 0.42,
      ),
      FoodComponentModel(
        id: 'comp_3',
        name: 'Tempe Kacang',
        estimatedGram: 100,
        compartmentNumber: 1,
        category: 'Lauk',
        confidencePercentage: 96,
        complianceStatus: 'Memenuhi AKG',
        iconData: Icons.restaurant_menu_rounded,
        calories: 201,
        protein: 19.9,
        fat: 8.8,
        carbohydrate: 13.5,
        fiber: 1.4,
      ),
      FoodComponentModel(
        id: 'comp_4',
        name: 'Lalapan Segar',
        estimatedGram: 30,
        compartmentNumber: 2,
        category: 'Lalapan',
        confidencePercentage: 95,
        complianceStatus: 'Memenuhi AKG',
        iconData: Icons.eco_outlined,
        calories: 26.25,
        protein: 1.5,
        fat: 0.3,
        carbohydrate: 4.5,
        fiber: 1.875,
      ),
      FoodComponentModel(
        id: 'comp_5',
        name: 'Susu UHT & Pisang',
        estimatedGram: 215,
        compartmentNumber: 5,
        category: 'Susu & Buah',
        confidencePercentage: 99,
        complianceStatus: 'Memenuhi AKG',
        iconData: Icons.local_drink_rounded,
        calories: 163.5,
        protein: 5.3,
        fat: 3.3,
        carbohydrate: 32.8,
        fiber: 2.6,
      ),
    ];
  }
}
