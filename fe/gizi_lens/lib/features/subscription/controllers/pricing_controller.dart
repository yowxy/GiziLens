import 'package:flutter/material.dart';
import '../models/pricing_plan_model.dart';

class PricingController extends ChangeNotifier {
  final List<PricingPlanModel> plans = PricingPlanModel.defaultPlans;

  late PricingPlanModel _selectedPlan;
  int _selectedTabIndex = 1; // Default to Paket SPPG Pro (index 1)

  PricingPlanModel get selectedPlan => _selectedPlan;
  int get selectedTabIndex => _selectedTabIndex;

  PricingController() {
    _selectedPlan = plans[1]; // SPPG Pro
  }

  void selectPlan(PricingPlanModel plan) {
    if (_selectedPlan.id != plan.id) {
      _selectedPlan = plan;
      final idx = plans.indexWhere((p) => p.id == plan.id);
      if (idx != -1) _selectedTabIndex = idx;
      notifyListeners();
    }
  }

  void selectIndex(int index) {
    if (index >= 0 && index < plans.length) {
      _selectedTabIndex = index;
      _selectedPlan = plans[index];
      notifyListeners();
    }
  }

  static const List<Map<String, String>> faqs = [
    {
      'question': 'Bagaimana mekanisme pembayaran via Midtrans Sandbox?',
      'answer':
          'Pembayaran menggunakan simulasi Midtrans Sandbox resmi. Anda dapat menguji seluruh metode (QRIS, BCA/Mandiri/BRI Virtual Account, atau Kartu Kredit tes) secara instan tanpa memotong saldo riil.',
    },
    {
      'question': 'Apakah laporan hasil audit terstandarisasi BGN & Kemenkes?',
      'answer':
          'Ya, seluruh rekapitulasi gizi dan kepatuhan AKG yang dihasilkan langsung disesuaikan dengan Kepmenkes RI No. 28/2019 dan Petunjuk Teknis Program MBG BGN 2024.',
    },
    {
      'question': 'Apakah paket langganan dapat dipindahtangankan ke unit SPPG lain?',
      'answer':
          'Lisensi paket terikat dengan akun dan unit operasional terdaftar. Anda dapat memperbarui unit operasional melalui menu Edit Profil Petugas.',
    },
  ];
}
