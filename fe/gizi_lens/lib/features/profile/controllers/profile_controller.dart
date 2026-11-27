import 'package:flutter/material.dart';
import '../../../../core/services/scan_quota_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/officer_account_model.dart';

class ProfileController extends ChangeNotifier {
  /// Number of free inspection scans granted each calendar month.
  static const int monthlyScanQuota = ScanQuotaService.freeMonthlyQuota;

  /// Scans included in the paid GiziLens Premium subscription per month.
  static const int premiumScanQuota = ScanQuotaService.premiumMonthlyQuota;

  int _activeNavIndex = 3;
  int _monthlyScansUsed = 0;

  bool _isSaving = false;

  OfficerAccountModel get account => UserSessionService.instance.account;
  int get activeNavIndex => _activeNavIndex;
  int get monthlyScansUsed => _monthlyScansUsed;
  bool get isSaving => _isSaving;
  bool get notificationsEnabled => NotificationService.instance.enabled;
  bool get hasUnreadNotifications => NotificationService.instance.hasUnread;

  ProfileController() {
    UserSessionService.instance.addListener(_onUserSessionUpdated);
    NotificationService.instance.addListener(_onUserSessionUpdated);
    // Ensure profile data is loaded from Firestore even if the user
    // navigates directly to Profile without going through Dashboard first
    // (e.g. after app kill → relaunch → auto-login → tap Profile tab).
    Future.microtask(() {
      loadProfile();
      _loadMonthlyUsage();
    });
  }

  Future<void> loadProfile() async {
    await UserSessionService.instance.initializeFromFirebase();
    notifyListeners();
  }

  /// Counts inspections created since the first day of the current month so
  /// the subscription card can display live quota usage.
  Future<void> _loadMonthlyUsage() async {
    final quota = await ScanQuotaService.instance.load();
    if (quota.used != _monthlyScansUsed) {
      _monthlyScansUsed = quota.used;
      notifyListeners();
    }
  }

  void _onUserSessionUpdated() {
    notifyListeners();
  }

  @visibleForTesting
  static void resetForTesting() {
    UserSessionService.instance.resetForTesting();
  }

  void setNavIndex(int index) {
    if (_activeNavIndex == index) return;
    _activeNavIndex = index;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    NotificationService.instance.setEnabled(value);
  }

  /// Updates the officer profile in memory, Firebase Auth, and Cloud Firestore.
  Future<bool> updateProfile({
    required String fullName,
    String? role,
    String? unit,
    String? region,
    String? officerId,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      return await UserSessionService.instance.updateProfile(
        fullName: fullName,
        role: role,
        unit: unit,
        region: region,
        officerId: officerId,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Compatibility alias for updating officer name.
  Future<void> updateProfileName(String newName) async {
    await updateProfile(fullName: newName);
  }

  @override
  void dispose() {
    UserSessionService.instance.removeListener(_onUserSessionUpdated);
    NotificationService.instance.removeListener(_onUserSessionUpdated);
    super.dispose();
  }
}
