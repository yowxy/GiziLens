import 'package:flutter/material.dart';

enum BillingCycle {
  monthly,
  annual,
}

/// Model representing the single GiziLens Premium subscription plan.
class PricingPlanModel {
  final String id;
  final String name;
  final String tagline;
  final int monthlyEquivalentPrice;
  final int billedPrice;
  final int? originalPrice;
  final String billingPeriod;
  final bool isPopular;
  final String? badgeText;
  final List<String> bundleHighlights;
  final List<String> features;
  final String ctaLabel;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;

  const PricingPlanModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.monthlyEquivalentPrice,
    required this.billedPrice,
    this.originalPrice,
    required this.billingPeriod,
    this.isPopular = true,
    this.badgeText,
    this.bundleHighlights = const [],
    required this.features,
    this.ctaLabel = 'Aktifkan GiziLens Premium',
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
  });

  int get savingsPercentage {
    if (originalPrice == null || originalPrice! <= billedPrice) return 0;
    return (((originalPrice! - billedPrice) / originalPrice!) * 100).round();
  }

  static PricingPlanModel get defaultPlan => defaultPlans.first;

  factory PricingPlanModel.fromApiJson(Map<String, dynamic> json) {
    final fallback = defaultPlan;
    final rawFeatures = json['features'];
    final features = rawFeatures is List && rawFeatures.isNotEmpty
        ? rawFeatures.map((e) => e.toString()).toList()
        : fallback.features;
    final rawHighlights = json['bundleHighlights'];
    final highlights = rawHighlights is List && rawHighlights.isNotEmpty
        ? rawHighlights.map((e) => e.toString()).toList()
        : fallback.bundleHighlights;

    return PricingPlanModel(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : fallback.id,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : fallback.name,
      tagline: (json['tagline'] as String?)?.trim().isNotEmpty == true
          ? json['tagline'] as String
          : fallback.tagline,
      monthlyEquivalentPrice:
          (json['monthlyEquivalentPrice'] as num?)?.toInt() ??
          fallback.monthlyEquivalentPrice,
      billedPrice:
          (json['billedPrice'] as num?)?.toInt() ?? fallback.billedPrice,
      originalPrice:
          (json['originalPrice'] as num?)?.toInt() ?? fallback.originalPrice,
      billingPeriod: (json['billingPeriod'] as String?)?.trim().isNotEmpty == true
          ? json['billingPeriod'] as String
          : fallback.billingPeriod,
      isPopular: json['isPopular'] as bool? ?? true,
      badgeText: (json['badgeText'] as String?) ?? fallback.badgeText,
      bundleHighlights: highlights,
      features: features,
      ctaLabel: (json['ctaLabel'] as String?) ?? fallback.ctaLabel,
      icon: Icons.workspace_premium_rounded,
      primaryColor: fallback.primaryColor,
      accentColor: fallback.accentColor,
    );
  }

  static const List<PricingPlanModel> defaultPlans = [
    PricingPlanModel(
      id: 'plan_premium',
      name: 'GiziLens Premium',
      tagline:
          '500 scan ompreng AI per bulan, ekspor laporan PDF resmi, dan sinkronisasi SPPG Cloud',
      monthlyEquivalentPrice: 299000,
      billedPrice: 299000,
      billingPeriod: 'per bulan',
      isPopular: true,
      badgeText: 'PAKET PREMIUM RESMI',
      bundleHighlights: [
        '500 Scan AI / bulan',
        'Ekspor PDF & XLSX',
        'Prioritas BGN',
      ],
      features: [
        'Kuota 500 scan ompreng AI per bulan (± 16 scan/hari kalender)',
        'Ekspor laporan resmi PDF (Watermark + SHA-256) & Excel (XLSX)',
        'Multi-demografis sasaran AKG (SD 1–3, SD 4–6, SMP, SMA)',
        'Notifikasi otomatis & peringatan defisit porsi >15%',
        'Sinkronisasi cloud terenkripsi & riwayat audit 12 bulan',
        'Dukungan teknis prioritas tim BGN & SPPG',
      ],
      ctaLabel: 'Aktifkan GiziLens Premium',
      icon: Icons.workspace_premium_rounded,
      primaryColor: Color(0xFF0F3628),
      accentColor: Color(0xFFD6A24A),
    ),
  ];
}
