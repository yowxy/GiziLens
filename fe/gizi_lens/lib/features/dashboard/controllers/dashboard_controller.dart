import 'package:flutter/material.dart';
import '../models/dashboard_stats_model.dart';

/// Controller managing state, active tab navigation, and period filtering for Dashboard.
class DashboardController extends ChangeNotifier {
  int _activeNavIndex = 0;
  MonitoringPeriod _selectedPeriod = MonitoringPeriod.hariIni;
  bool _hasUnreadNotifications = true;
  DashboardStatsModel _stats = const DashboardStatsModel();

  int get activeNavIndex => _activeNavIndex;
  MonitoringPeriod get selectedPeriod => _selectedPeriod;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  DashboardStatsModel get stats => _stats;

  void setNavIndex(int index) {
    if (_activeNavIndex != index) {
      _activeNavIndex = index;
      notifyListeners();
    }
  }

  void setPeriod(MonitoringPeriod period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      // In real scenario, filter stats according to period
      _stats = _stats.copyWith(period: period);
      notifyListeners();
    }
  }

  void toggleNotifications() {
    _hasUnreadNotifications = false;
    notifyListeners();
  }
}
