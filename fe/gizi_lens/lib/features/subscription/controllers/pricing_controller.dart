import 'package:flutter/material.dart';
import '../../../../core/services/backend_api_service.dart';
import '../models/pricing_plan_model.dart';

class PricingController extends ChangeNotifier {
  List<PricingPlanModel> _plans = List<PricingPlanModel>.from(
    PricingPlanModel.defaultPlans,
  );
  late PricingPlanModel _selectedPlan;
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  bool _disposed = false;

  List<PricingPlanModel> get plans => List.unmodifiable(_plans);
  PricingPlanModel get selectedPlan => _selectedPlan;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _isLoading;

  PricingController() {
    _selectedPlan = _plans.first;
    loadPlans();
  }

  Future<void> loadPlans() async {
    _isLoading = true;
    _safeNotify();
    try {
      final remote = await BackendApiService.instance.fetchPlans();
      if (_disposed) return;
      if (remote.isNotEmpty) {
        final singlePlan = PricingPlanModel.fromApiJson(remote.first);
        _plans = [singlePlan];
        _selectedPlan = singlePlan;
        _selectedTabIndex = 0;
      }
    } catch (_) {
      // Keep default single Premium plan when offline or in tests.
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void selectPlan(PricingPlanModel plan) {
    if (_selectedPlan.id != plan.id) {
      _selectedPlan = plan;
      final idx = _plans.indexWhere((p) => p.id == plan.id);
      if (idx != -1) _selectedTabIndex = idx;
      _safeNotify();
    }
  }

  void selectIndex(int index) {
    if (index >= 0 && index < _plans.length) {
      _selectedTabIndex = index;
      _selectedPlan = _plans[index];
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static const List<Map<String, String>> faqs = [
    {
      'question': 'Berapa harga dan kuota GiziLens Premium?',
      'answer':
          'Rp299.000 per bulan (belum termasuk PPN 11%) dengan kuota 500 scan ompreng AI, sekitar 16 scan per hari kalender atau ± Rp598 per scan. Harga ini mencakup biaya layanan AI, infrastruktur server, database, penyimpanan dokumentasi pemeriksaan, pemeliharaan sistem, dan pengembangan fitur berkelanjutan.',
    },
    {
      'question': 'Bagaimana mekanisme pembayaran via Midtrans?',
      'answer':
          'Pembayaran diproses melalui Midtrans Payment Gateway resmi (QRIS, Virtual Account BCA/Mandiri/BRI/BNI, atau Kartu Kredit/Debit 3D Secure). Status langganan Premium aktif otomatis setelah pembayaran terkonfirmasi.',
    },
    {
      'question': 'Apakah laporan hasil audit terstandarisasi BGN & Kemenkes?',
      'answer':
          'Ya, seluruh rekapitulasi gizi dan kepatuhan AKG yang dihasilkan langsung disesuaikan dengan Kepmenkes RI No. 28/2019 dan Petunjuk Teknis Program MBG BGN 2024, dilengkapi watermark dan hash SHA-256.',
    },
    {
      'question': 'Apakah paket GiziLens Premium terikat dengan unit SPPG?',
      'answer':
          'Lisensi Premium terikat dengan akun dan unit operasional terdaftar. Anda dapat memperbarui informasi unit operasional kapan saja melalui menu Edit Profil Petugas.',
    },
  ];
}
