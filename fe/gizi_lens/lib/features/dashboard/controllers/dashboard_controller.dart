import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/wib_time.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/dashboard_stats_model.dart';

/// Controller managing state, active tab navigation, period filtering, and live Firestore sync for Dashboard.
class DashboardController extends ChangeNotifier {
  int _activeNavIndex = 0;
  MonitoringPeriod _selectedPeriod = MonitoringPeriod.hariIni;

  DashboardStatsModel _stats = const DashboardStatsModel();

  final String _greeting = _resolveGreeting();

  int get activeNavIndex => _activeNavIndex;
  MonitoringPeriod get selectedPeriod => _selectedPeriod;
  bool get hasUnreadNotifications => NotificationService.instance.hasUnread;
  DashboardStatsModel get stats => _stats;

  String get officerName {
    final name = UserSessionService.instance.account.fullName.trim();
    return name.isEmpty || name == '-' ? AppStrings.dashboardOfficerName : name;
  }

  String get unitName {
    final unit = UserSessionService.instance.account.unitOperational.trim();
    return unit.isEmpty || unit == '-' ? AppStrings.dashboardOfficerUnit : unit;
  }

  String get greeting => _greeting;

  static String _resolveGreeting() {
    final hour = WibTime.calendar(DateTime.now()).hour;
    if (hour < 11) return AppStrings.greetingMorning;
    if (hour < 15) return AppStrings.greetingAfternoon;
    if (hour < 18) return AppStrings.greetingEvening;
    return AppStrings.greetingNight;
  }

  DashboardController() {
    UserSessionService.instance.addListener(_onUserSessionChanged);
    NotificationService.instance.addListener(_onUserSessionChanged);
    Future.microtask(() {
      loadStatsFromFirestore();
      loadUserProfile();
      loadNotifications();
    });
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
    final today = WibTime.startOfDayUtc(DateTime.now());
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
