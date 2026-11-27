import 'package:flutter/material.dart';

import '../../../../core/services/scan_quota_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/officer_account_model.dart';

class ProfileController extends ChangeNotifier {
  static const int monthlyScanQuota =
      ScanQuotaService.freeMonthlyQuota;

  static const int premiumScanQuota =
      ScanQuotaService.premiumMonthlyQuota;

  int _activeNavIndex = 3;
  int _monthlyScansUsed = 0;

  ScanQuota? _serverQuota;

  bool _isSaving = false;
  bool _disposed = false;

  OfficerAccountModel get account =>
      UserSessionService.instance.account;

  int get activeNavIndex => _activeNavIndex;

  int get monthlyScansUsed =>
      _monthlyScansUsed;

  int get monthlyQuota =>
      _serverQuota?.limit ??
      (
        account.isPremium
            ? premiumScanQuota
            : monthlyScanQuota
      );

  bool get quotaAvailable =>
      _serverQuota?.available == true;

  bool get isSaving => _isSaving;

  bool get notificationsEnabled =>
      NotificationService.instance.enabled;

  bool get hasUnreadNotifications =>
      NotificationService.instance.hasUnread;

  ProfileController() {
    UserSessionService.instance.addListener(
      _onUserSessionUpdated,
    );

    NotificationService.instance.addListener(
      _onUserSessionUpdated,
    );

    Future.microtask(() {
      loadProfile();
      _loadMonthlyUsage();
    });
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    await UserSessionService.instance
        .initializeFromFirebase();

    _safeNotify();
  }

  Future<void> _loadMonthlyUsage() async {
    final quota =
        await ScanQuotaService.instance.load();

    if (_disposed) return;

    _serverQuota = quota;

    if (quota.available) {
      _monthlyScansUsed = quota.used;
    }

    _safeNotify();
  }

  Future<void> refreshQuota() async {
    await _loadMonthlyUsage();
  }

  void _onUserSessionUpdated() {
    _safeNotify();
  }

  @visibleForTesting
  static void resetForTesting() {
    UserSessionService.instance.resetForTesting();
  }

  void setNavIndex(int index) {
    if (_activeNavIndex == index) return;

    _activeNavIndex = index;

    _safeNotify();
  }

  void toggleNotifications(bool value) {
    NotificationService.instance.setEnabled(value);
  }

  Future<bool> updateProfile({
    required String fullName,
    String? role,
    String? unit,
    String? region,
    String? officerId,
  }) async {
    _isSaving = true;

    _safeNotify();

    try {
      return await UserSessionService.instance
          .updateProfile(
        fullName: fullName,
        role: role,
        unit: unit,
        region: region,
        officerId: officerId,
      );
    } finally {
      _isSaving = false;

      _safeNotify();
    }
  }

  Future<void> updateProfileName(
    String newName,
  ) async {
    await updateProfile(
      fullName: newName,
    );
  }

  @override
  void dispose() {
    _disposed = true;

    UserSessionService.instance.removeListener(
      _onUserSessionUpdated,
    );

    NotificationService.instance.removeListener(
      _onUserSessionUpdated,
    );

    super.dispose();
  }
}