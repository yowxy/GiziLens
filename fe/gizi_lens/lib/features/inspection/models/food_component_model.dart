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
  final Rect? boundingBox;

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
    this.boundingBox,
  });
}
