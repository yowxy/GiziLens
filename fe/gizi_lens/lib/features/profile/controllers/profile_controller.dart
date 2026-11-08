import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/officer_account_model.dart';

class ProfileController extends ChangeNotifier {
  OfficerAccountModel _account = OfficerAccountModel.defaultAccount();
  int _activeNavIndex = 3;
  bool _notificationsEnabled = true;

  OfficerAccountModel get account => _account;
  int get activeNavIndex => _activeNavIndex;
  bool get notificationsEnabled => _notificationsEnabled;

  ProfileController() {
    _loadProfileFromFirebase();
  }

  Future<void> _loadProfileFromFirebase() async {
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user == null) return;

      final profileData = await FirestoreService.instance.getUserProfile(user.uid);
      final name = profileData?['fullName'] as String? ??
          user.displayName ??
          _account.fullName;
      final role = profileData?['role'] as String? ?? _account.roleTitle;
      final unit = profileData?['unit'] as String? ?? _account.unitOperational;
      final officerId = profileData?['officerId'] as String? ??
          'BGN-2024-${user.uid.length >= 5 ? user.uid.substring(0, 5).toUpperCase() : "SPPG"}';

      final initials = name
          .trim()
          .split(' ')
          .where((s) => s.isNotEmpty)
          .take(2)
          .map((s) => s[0].toUpperCase())
          .join();

      _account = _account.copyWith(
        fullName: name,
        initials: initials.isNotEmpty ? initials : _account.initials,
        roleTitle: role,
        unitOperational: unit,
        officerId: officerId,
      );
      notifyListeners();
    } catch (_) {}
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
    if (!_account.hasNotification) return;
    _account = _account.copyWith(hasNotification: false);
    notifyListeners();
  }

  void updateProfileName(String newName) async {
    final initials = newName
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    _account = _account.copyWith(
      fullName: newName,
      initials: initials.isNotEmpty ? initials : _account.initials,
    );
    notifyListeners();

    try {
      await FirestoreService.instance.updateCurrentUserProfile({
        'fullName': newName,
      });
    } catch (_) {}
  }
}
