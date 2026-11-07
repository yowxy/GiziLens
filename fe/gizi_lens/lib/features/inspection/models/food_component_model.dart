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
      ),
    ];
  }
}
