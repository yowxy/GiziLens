import 'package:flutter/material.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/officer_account_model.dart';

class ProfileController extends ChangeNotifier {
  int _activeNavIndex = 3;
  bool _notificationsEnabled = true;

  OfficerAccountModel get account => UserSessionService.instance.account;
  int get activeNavIndex => _activeNavIndex;
  bool get notificationsEnabled => _notificationsEnabled;

  ProfileController() {
    UserSessionService.instance.addListener(_onUserSessionUpdated);
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
    _notificationsEnabled = value;
    notifyListeners();
  }

  void dismissNotificationBadge() {
    UserSessionService.instance.dismissNotification();
  }

  /// Updates the officer profile in memory, Firebase Auth, and Cloud Firestore.
  Future<bool> updateProfile({
    required String fullName,
    String? role,
    String? unit,
    String? region,
    String? officerId,
  }) async {
    return await UserSessionService.instance.updateProfile(
      fullName: fullName,
      role: role,
      unit: unit,
      region: region,
      officerId: officerId,
    );
  }

  /// Compatibility alias for updating officer name.
  Future<void> updateProfileName(String newName) async {
    await updateProfile(fullName: newName);
  }

  @override
  void dispose() {
    UserSessionService.instance.removeListener(_onUserSessionUpdated);
    super.dispose();
  }
}
