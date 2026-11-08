import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../models/officer_account_model.dart';

class ProfileController extends ChangeNotifier {
  static OfficerAccountModel _activeAccount = OfficerAccountModel.defaultAccount();

  int _activeNavIndex = 3;
  bool _notificationsEnabled = true;

  OfficerAccountModel get account => _activeAccount;
  int get activeNavIndex => _activeNavIndex;
  bool get notificationsEnabled => _notificationsEnabled;

  ProfileController() {
    _loadProfileFromFirebase();
  }

  @visibleForTesting
  static void resetForTesting() {
    _activeAccount = OfficerAccountModel.defaultAccount();
  }

  Future<void> _loadProfileFromFirebase() async {
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user == null) return;

      final profileData = await FirestoreService.instance.getUserProfile(user.uid);
      String? name = profileData?['fullName'] as String?;
      if (name == null || name.trim().isEmpty || name == 'Petugas SPPG') {
        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          name = user.displayName!.trim();
        } else if (user.email != null && user.email!.isNotEmpty) {
          name = FirebaseAuthService.formatNameFromEmail(user.email!);
        } else {
          name = _activeAccount.fullName;
        }
      }
      final role = profileData?['role'] as String? ?? _activeAccount.roleTitle;
      final unit = profileData?['unit'] as String? ?? _activeAccount.unitOperational;
      final region = profileData?['region'] as String? ?? _activeAccount.unitRegion;
      final officerId = profileData?['officerId'] as String? ??
          'BGN-2024-${user.uid.length >= 5 ? user.uid.substring(0, 5).toUpperCase() : "SPPG"}';

      final initials = name
          .trim()
          .split(' ')
          .where((s) => s.isNotEmpty)
          .take(2)
          .map((s) => s[0].toUpperCase())
          .join();

      _activeAccount = _activeAccount.copyWith(
        fullName: name,
        initials: initials.isNotEmpty ? initials : _activeAccount.initials,
        roleTitle: role,
        unitOperational: unit,
        unitRegion: region,
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
    if (!_activeAccount.hasNotification) return;
    _activeAccount = _activeAccount.copyWith(hasNotification: false);
    notifyListeners();
  }

  /// Updates the officer profile in memory, Firebase Auth, and Cloud Firestore.
  Future<bool> updateProfile({
    required String fullName,
    String? role,
    String? unit,
    String? region,
  }) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) return false;

    final initials = trimmedName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    _activeAccount = _activeAccount.copyWith(
      fullName: trimmedName,
      initials: initials.isNotEmpty ? initials : _activeAccount.initials,
      roleTitle: (role != null && role.trim().isNotEmpty) ? role.trim() : _activeAccount.roleTitle,
      unitOperational: (unit != null && unit.trim().isNotEmpty) ? unit.trim() : _activeAccount.unitOperational,
      unitRegion: (region != null && region.trim().isNotEmpty) ? region.trim() : _activeAccount.unitRegion,
    );
    notifyListeners();

    // 1. Update Firebase Auth displayName
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(trimmedName);
      }
    } catch (e) {
      debugPrint('Notice updating Firebase Auth displayName: $e');
    }

    // 2. Update Cloud Firestore
    try {
      final data = <String, dynamic>{
        'fullName': trimmedName,
        if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
        if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
      };
      await FirestoreService.instance.updateCurrentUserProfile(data);
      return true;
    } catch (e) {
      debugPrint('Notice updating Firestore user profile: $e');
      return true;
    }
  }

  /// Compatibility alias for updating officer name.
  Future<void> updateProfileName(String newName) async {
    await updateProfile(fullName: newName);
  }
}
