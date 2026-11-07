import 'package:flutter/material.dart';
import '../models/officer_account_model.dart';

class ProfileController extends ChangeNotifier {
  OfficerAccountModel _account = OfficerAccountModel.defaultAccount();
  int _activeNavIndex = 3;
  bool _notificationsEnabled = true;

  OfficerAccountModel get account => _account;
  int get activeNavIndex => _activeNavIndex;
  bool get notificationsEnabled => _notificationsEnabled;

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

  void updateProfileName(String newName) {
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
  }
}
