import 'package:flutter/material.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/dashboard_stats_model.dart';

/// Controller managing state, active tab navigation, period filtering, and live Firestore sync for Dashboard.
class DashboardController extends ChangeNotifier {
  int _activeNavIndex = 0;
  MonitoringPeriod _selectedPeriod = MonitoringPeriod.hariIni;
  bool _hasUnreadNotifications = true;
  DashboardStatsModel _stats = const DashboardStatsModel();

  int get activeNavIndex => _activeNavIndex;
  MonitoringPeriod get selectedPeriod => _selectedPeriod;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  DashboardStatsModel get stats => _stats;

  DashboardController() {
    loadStatsFromFirestore();
  }

  Future<void> loadStatsFromFirestore() async {
    try {
      final statsMap = await FirestoreService.instance.getDashboardStats();
      final total = statsMap['total'] ?? 0;
      final sesuai = statsMap['sesuai'] ?? 0;
      final tidakSesuai = statsMap['tidakSesuai'] ?? 0;

      _stats = _stats.copyWith(
        totalDiperiksa: total,
        totalSesuai: sesuai,
        totalTidakSesuai: tidakSesuai,
      );
      notifyListeners();
    } catch (_) {}
  }

  void setNavIndex(int index) {
    if (_activeNavIndex != index) {
      _activeNavIndex = index;
      notifyListeners();
    }
  }

  void setPeriod(MonitoringPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      _stats = _stats.copyWith(period: period);
      notifyListeners();
    }
  }

  void toggleNotifications() {
    _hasUnreadNotifications = false;
    notifyListeners();
  }
}
