import 'package:flutter/foundation.dart';
import '../../features/profile/models/officer_account_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Central singleton service maintaining live user session state,
/// synchronized across Profile, Dashboard, and CompleteProfile.
class UserSessionService extends ChangeNotifier {
  UserSessionService._() {
    initializeFromFirebase();
  }

  static final UserSessionService instance = UserSessionService._();

  OfficerAccountModel _account = OfficerAccountModel.defaultAccount();

  OfficerAccountModel get account => _account;


  void resetForTesting() {
    _account = OfficerAccountModel.defaultAccount();
    notifyListeners();
  }

  /// Reset session state to defaults. Called on logout so the next login
  /// starts clean instead of showing stale profile data.
  void reset() {
    _account = OfficerAccountModel.defaultAccount();
    notifyListeners();
  }

  /// Initialize user details from current FirebaseAuth session and Firestore.
  Future<void> initializeFromFirebase() async {
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user == null) return;

      // 1. Initial quick population from Auth user object
      String resolvedName = _account.fullName;
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        resolvedName = user.displayName!.trim();
      } else if (user.email != null && user.email!.isNotEmpty) {
        resolvedName = FirebaseAuthService.formatNameFromEmail(user.email!);
      }

      final initials = _computeInitials(resolvedName);
      final officerId = FirebaseAuthService.buildOfficerId(user.uid);

      _account = _account.copyWith(
        fullName: resolvedName,
        initials: initials.isNotEmpty ? initials : _account.initials,
        officerId: officerId,
      );
      notifyListeners();

      // 2. Fetch extended metadata from Firestore
      final profileData = await FirestoreService.instance.getUserProfile(user.uid);
      if (profileData != null) {
        final fsName = profileData['fullName'] as String?;
        final fsRole = profileData['role'] as String?;
        final fsUnit = profileData['unit'] as String?;
        final fsRegion = profileData['region'] as String?;
        final fsOfficerId = profileData['officerId'] as String?;

        String finalName = resolvedName;
        if (fsName != null && fsName.trim().isNotEmpty && fsName != 'Petugas SPPG') {
          finalName = fsName.trim();
        }

        final finalInitials = _computeInitials(finalName);

        _account = _account.copyWith(
          fullName: finalName,
          initials: finalInitials.isNotEmpty ? finalInitials : _account.initials,
          roleTitle: (fsRole != null && fsRole.trim().isNotEmpty) ? fsRole.trim() : _account.roleTitle,
          unitOperational: (fsUnit != null && fsUnit.trim().isNotEmpty) ? fsUnit.trim() : _account.unitOperational,
          unitRegion: (fsRegion != null && fsRegion.trim().isNotEmpty) ? fsRegion.trim() : _account.unitRegion,
          officerId: (fsOfficerId != null && fsOfficerId.trim().isNotEmpty) ? fsOfficerId.trim() : _account.officerId,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Notice loading UserSession from Firebase: $e');
    }
  }

  /// Update active officer profile and immediately persist to Firebase Auth and Cloud Firestore.
  /// Returns true only if the Firestore write succeeded.
  Future<bool> updateProfile({
    required String fullName,
    String? role,
    String? unit,
    String? region,
    String? officerId,
  }) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) return false;

    final initials = _computeInitials(trimmedName);

    _account = _account.copyWith(
      fullName: trimmedName,
      initials: initials.isNotEmpty ? initials : _account.initials,
      roleTitle: (role != null && role.trim().isNotEmpty) ? role.trim() : _account.roleTitle,
      unitOperational: (unit != null && unit.trim().isNotEmpty) ? unit.trim() : _account.unitOperational,
      unitRegion: (region != null && region.trim().isNotEmpty) ? region.trim() : _account.unitRegion,
      officerId: (officerId != null && officerId.trim().isNotEmpty) ? officerId.trim() : _account.officerId,
    );
    notifyListeners();

    // 1. Sync Firebase Auth Display Name (non-critical if this fails)
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(trimmedName);
      }
    } catch (e) {
      debugPrint('Notice updating Auth displayName: $e');
    }

    // 2. Sync Cloud Firestore — this must succeed or data is lost on app kill
    final data = <String, dynamic>{
      'fullName': trimmedName,
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
      if (officerId != null && officerId.trim().isNotEmpty) 'officerId': officerId.trim(),
    };
    final ok = await FirestoreService.instance.updateCurrentUserProfile(data);
    if (!ok) {
      debugPrint('updateProfile: Firestore write FAILED — data may not persist');
    }
    return ok;
  }

  static String _computeInitials(String name) {
    return name
        .trim()
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();
  }
}
