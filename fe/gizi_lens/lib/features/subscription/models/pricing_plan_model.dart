import 'package:flutter/material.dart';

enum BillingCycle {
  monthly,
  annual,
}

/// Model representing a subscription bundling package in GiziLens SPPG.
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
    this.isPopular = false,
    this.badgeText,
    this.bundleHighlights = const [],
    required this.features,
    this.ctaLabel = 'Pilih Paket Ini',
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
  });

  int get savingsPercentage {
    if (originalPrice == null || originalPrice! <= billedPrice) return 0;
    return (((originalPrice! - billedPrice) / originalPrice!) * 100).round();
  }

  static const List<PricingPlanModel> defaultPlans = [
    PricingPlanModel(
      id: 'plan_starter',
      name: 'Paket Mandiri',
      tagline: 'Ideal untuk Ahli Gizi & Auditor SPPG Lapangan Mandiri',
      monthlyEquivalentPrice: 99000,
      billedPrice: 99000,
      billingPeriod: 'per bulan',
      isPopular: false,
      icon: Icons.person_outline_rounded,
      primaryColor: Color(0xFF1B4E41),
      accentColor: Color(0xFF3FC2F2),
      bundleHighlights: ['∞ Scan AI', 'Ekspor PDF', '1 Akun'],
      features: [
        'Scan Ompreng AI tanpa batasan kuota harian/bulanan',
        'Deteksi 5 Pilar Nutrisi (Pokok, Hewani, Nabati, Sayur, Buah)',
        'Standar Toleransi Deviasi AKG Kemenkes & Juknis BGN 2024',
        'Ekspor Ringkasan Hasil Pemeriksaan (Format PDF Standar)',
        'Penyimpanan Riwayat Audit 30 Hari Terakhir',
      ],
    ),
    PricingPlanModel(
      id: 'plan_pro',
      name: 'Paket SPPG Pro',
      tagline: 'Paling direkomendasikan untuk Dapur Unit MBG & Sekolah',
      monthlyEquivalentPrice: 83000,
      billedPrice: 249000,
      originalPrice: 297000,
      billingPeriod: 'per 3 bulan (Rp 83rb/bln)',
      isPopular: true,
      badgeText: '⭐ PALING POPULER',
      icon: Icons.workspace_premium_rounded,
      primaryColor: Color(0xFF0F3628),
      accentColor: Color(0xFFD6A24A),
      bundleHighlights: ['∞ Scan AI', 'XLSX & PDF', 'Audit 1 Thn'],
      features: [
        'Semua fitur Paket Mandiri disertakan',
        'Ekspor Otomatis Laporan Lengkap Excel (XLSX) & PDF Resmi',
        'Multi-Demografis Sasaran (SD 1-3, SD 4-6, SMP, SMA)',
        'Notifikasi Otomatis & Peringatan Defisit Porsi >15%',
        'Prioritas Kecepatan AI Recognition (<1 detik per ompreng)',
        'Penyimpanan Cloud Terenkripsi & Audit Trail 1 Tahun',
      ],
    ),
    PricingPlanModel(
      id: 'plan_enterprise',
      name: 'Paket Sentral MBG',
      tagline: 'Solusi Lengkap SPPG Sentral, Korwil & Koordinator Wilayah',
      monthlyEquivalentPrice: 58000,
      billedPrice: 699000,
      originalPrice: 1188000,
      billingPeriod: 'per tahun (Rp 58rb/bln)',
      isPopular: false,
      badgeText: '👑 TERLENGKAP - HEMAT 41%',
      icon: Icons.domain_rounded,
      primaryColor: Color(0xFF102A4A),
      accentColor: Color(0xFF38BDF8),
      bundleHighlights: ['5 Akun Auditor', 'Sync BGN', 'Helpdesk 24/7'],
      features: [
        'Semua fitur Paket SPPG Pro disertakan',
        'Multi-Akun Petugas (Hingga 5 Akun Auditor dalam 1 Unit)',
        'Sinkronisasi Real-time ke Portal Pusat Pengawasan BGN',
        'Laporan Kepatuhan Mutu Terakreditasi Nasional',
        'Dukungan Teknis & Helpdesk Prioritas 24/7 via WhatsApp',
        'Sertifikat Kepatuhan Mutu Digital Berkode QR Resmi',
      ],
    ),
  ];
}
