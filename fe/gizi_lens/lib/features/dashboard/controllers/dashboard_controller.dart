import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/dashboard_stats_model.dart';

/// Controller managing state, active tab navigation, period filtering, and live Firestore sync for Dashboard.
class DashboardController extends ChangeNotifier {
  int _activeNavIndex = 0;
  MonitoringPeriod _selectedPeriod = MonitoringPeriod.hariIni;

  DashboardStatsModel _stats = const DashboardStatsModel();

  final String _greeting = AppStrings.greetingWelcome;

  int get activeNavIndex => _activeNavIndex;
  MonitoringPeriod get selectedPeriod => _selectedPeriod;
  bool get hasUnreadNotifications => NotificationService.instance.hasUnread;
  DashboardStatsModel get stats => _stats;

  String get officerName => UserSessionService.instance.account.fullName;
  String get unitName => UserSessionService.instance.account.unitOperational;
  String get greeting => _greeting;

  DashboardController() {
    UserSessionService.instance.addListener(_onUserSessionChanged);
    NotificationService.instance.addListener(_onUserSessionChanged);
    loadStatsFromFirestore();
    loadUserProfile();
    loadNotifications();
  }

  void _onUserSessionChanged() {
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    await NotificationService.instance.loadSettings();
    final inspections = await FirestoreService.instance.getInspections();
    NotificationService.instance.updateFromInspections(inspections);
  }

  Future<void> loadUserProfile() async {
    await UserSessionService.instance.initializeFromFirebase();
    notifyListeners();
  }

  Future<void> loadStatsFromFirestore() async {
    try {
      final statsMap = await FirestoreService.instance.getDashboardStats(
        since: _periodStart(_selectedPeriod),
      );
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
      loadStatsFromFirestore();
    }
  }

  DateTime _periodStart(MonitoringPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (period) {
      MonitoringPeriod.hariIni => today,
      MonitoringPeriod.tujuhHari => today.subtract(const Duration(days: 6)),
      MonitoringPeriod.tigaPuluhHari => today.subtract(
        const Duration(days: 29),
      ),
    };
  }


  @override
  void dispose() {
    UserSessionService.instance.removeListener(_onUserSessionChanged);
    NotificationService.instance.removeListener(_onUserSessionChanged);
    super.dispose();
  }
}
