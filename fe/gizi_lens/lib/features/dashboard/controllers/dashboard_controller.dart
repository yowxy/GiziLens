import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/dashboard_stats_model.dart';

/// Controller managing state, active tab navigation, period filtering, and live Firestore sync for Dashboard.
class DashboardController extends ChangeNotifier {
  int _activeNavIndex = 0;
  MonitoringPeriod _selectedPeriod = MonitoringPeriod.hariIni;
  bool _hasUnreadNotifications = true;
  DashboardStatsModel _stats = const DashboardStatsModel();

  String _officerName = AppStrings.dashboardOfficerName;
  String _unitName = AppStrings.dashboardOfficerUnit;
  final String _greeting = AppStrings.greetingWelcome;

  int get activeNavIndex => _activeNavIndex;
  MonitoringPeriod get selectedPeriod => _selectedPeriod;
  bool get hasUnreadNotifications => _hasUnreadNotifications;
  DashboardStatsModel get stats => _stats;

  String get officerName => _officerName;
  String get unitName => _unitName;
  String get greeting => _greeting;

  DashboardController() {
    loadStatsFromFirestore();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user != null) {
        final profileData = await FirestoreService.instance.getUserProfile(user.uid);
        String? name = profileData?['fullName'] as String?;
        if (name == null || name.trim().isEmpty || name == 'Petugas SPPG') {
          if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
            name = user.displayName!.trim();
          } else if (user.email != null && user.email!.isNotEmpty) {
            name = FirebaseAuthService.formatNameFromEmail(user.email!);
          }
        }

        final unit = profileData?['unit'] as String?;

        if (name != null && name.trim().isNotEmpty) {
          _officerName = name.trim();
        }
        if (unit != null && unit.trim().isNotEmpty) {
          _unitName = unit.trim();
        }
        notifyListeners();
      }
    } catch (_) {}
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
