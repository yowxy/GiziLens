import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/profile/models/officer_account_model.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Central singleton service maintaining live user session state,
/// synchronized across Profile, Dashboard, and CompleteProfile.
class UserSessionService extends ChangeNotifier {
  UserSessionService._() {
    _listenAuthChanges();
    initializeFromFirebase();
  }

  static final UserSessionService instance = UserSessionService._();

  OfficerAccountModel _account = OfficerAccountModel.defaultAccount();
  StreamSubscription<User?>? _authSub;
  String? _lastLoadedUid;

  OfficerAccountModel get account => _account;

  void _listenAuthChanges() {
    try {
      if (!FirebaseAuthService.instance.isFirebaseInitialized) return;
      _authSub ??= FirebaseAuthService.instance.authStateChanges.listen((user) {
        if (user == null) {
          _lastLoadedUid = null;
          return;
        }
        if (user.uid != _lastLoadedUid) {
          initializeFromFirebase();
        }
      });
    } catch (_) {}
  }

  void resetForTesting() {
    _lastLoadedUid = null;
    _account = OfficerAccountModel.defaultAccount();
    notifyListeners();
  }

  /// Reset session state to defaults. Called on logout so the next login
  /// starts clean instead of showing stale profile data.
  void reset() {
    _lastLoadedUid = null;
    _account = OfficerAccountModel.defaultAccount();
    notifyListeners();
  }

  /// Initialize user details from current FirebaseAuth session and Cloud Firestore.
  Future<void> initializeFromFirebase() async {
    _listenAuthChanges();
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user == null) return;
      _lastLoadedUid = user.uid;

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
        isVerified: user.emailVerified || _account.isVerified,
      );
      notifyListeners();

      // 2. Fetch extended metadata from Cloud Firestore + Backend API
      final profileData = await FirestoreService.instance.getUserProfile(user.uid);
      if (profileData != null) {
        final fsName = profileData['fullName'] as String?;
        final fsRole = profileData['role'] as String?;
        final fsUnit = profileData['unit'] as String?;
        final fsRegion = profileData['region'] as String?;
        final fsOfficerId = profileData['officerId'] as String?;
        final fsIsVerified = profileData['isVerified'] as bool?;
        final fsSubscriptionPlan = profileData['subscriptionPlan'] as String?;
        final fsIsPremium = profileData['isPremium'] as bool?;

        String finalName = resolvedName;
        if (fsName != null &&
            fsName.trim().isNotEmpty &&
            fsName != 'Petugas SPPG' &&
            fsName != '-') {
          finalName = fsName.trim();
        }

        final finalInitials = _computeInitials(finalName);
        final resolvedIsPremium = fsIsPremium ?? _account.isPremium;
        final resolvedPlan = resolvedIsPremium &&
                fsSubscriptionPlan != null &&
                fsSubscriptionPlan.trim().isNotEmpty
            ? fsSubscriptionPlan.trim()
            : (resolvedIsPremium ? _account.subscriptionPlan : 'GiziLens Free');

        _account = _account.copyWith(
          fullName: finalName,
          initials: finalInitials.isNotEmpty ? finalInitials : _account.initials,
          roleTitle: (fsRole != null && fsRole.trim().isNotEmpty && fsRole.trim() != '-')
              ? fsRole.trim()
              : (_account.roleTitle == '-' ? 'Ahli Gizi Lapangan' : _account.roleTitle),
          unitOperational: (fsUnit != null && fsUnit.trim().isNotEmpty && fsUnit.trim() != '-')
              ? fsUnit.trim()
              : _account.unitOperational,
          unitRegion: (fsRegion != null && fsRegion.trim().isNotEmpty && fsRegion.trim() != '-')
              ? fsRegion.trim()
              : _account.unitRegion,
          officerId: (fsOfficerId != null && fsOfficerId.trim().isNotEmpty && fsOfficerId.trim() != '-')
              ? fsOfficerId.trim()
              : _account.officerId,
          isVerified: fsIsVerified ?? _account.isVerified,
          subscriptionPlan: resolvedPlan,
          isPremium: resolvedIsPremium,
        );
        notifyListeners();
      } else {
        // Seed basic Firestore document when missing so subsequent reads/edits succeed.
        await FirestoreService.instance.saveUserProfile(
          uid: user.uid,
          data: {
            'fullName': resolvedName,
            if (user.email != null) 'email': user.email,
            'role': 'Ahli Gizi Lapangan',
            'officerId': officerId,
            'isVerified': user.emailVerified,
          },
        );
      }
    } catch (e) {
      debugPrint('Notice loading UserSession from Firebase: $e');
    }
  }

  /// Upgrade active officer subscription tier to a premium bundle plan.
  Future<bool> upgradeSubscription({required String planName}) async {
    _account = _account.copyWith(
      subscriptionPlan: planName,
      isPremium: true,
    );
    notifyListeners();
    try {
      await FirestoreService.instance.updateCurrentUserProfile({
        'subscriptionPlan': planName,
        'isPremium': true,
        'upgradedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
    return true;
  }

  /// Update active officer profile and immediately persist to Firebase Auth,
  /// Cloud Firestore, and Backend PostgreSQL.
  Future<bool> updateProfile({
    required String fullName,
    String? role,
    String? unit,
    String? region,
    String? officerId,
  }) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) return false;

    final cleanRole = _cleanOptional(role);
    final cleanUnit = _cleanOptional(unit);
    final cleanRegion = _cleanOptional(region);
    final cleanOfficerId = _cleanOptional(officerId);
    final initials = _computeInitials(trimmedName);

    _account = _account.copyWith(
      fullName: trimmedName,
      initials: initials.isNotEmpty ? initials : _account.initials,
      roleTitle: cleanRole ?? _account.roleTitle,
      unitOperational: cleanUnit ?? _account.unitOperational,
      unitRegion: cleanRegion ?? _account.unitRegion,
      officerId: cleanOfficerId ?? _account.officerId,
    );
    notifyListeners();

    final user = FirebaseAuthService.instance.currentUser;
    if (user == null) {
      // Offline / unit-test mode without an authenticated Firebase user.
      return true;
    }

    // 1. Sync Firebase Auth Display Name
    try {
      await user.updateDisplayName(trimmedName);
    } catch (e) {
      debugPrint('Notice updating Auth displayName: $e');
    }

    // 2. Sync Cloud Firestore & Backend API
    final data = <String, dynamic>{
      'fullName': trimmedName,
      if (user.email != null && user.email!.isNotEmpty) 'email': user.email,
      'role': ?cleanRole,
      'unit': ?cleanUnit,
      'region': ?cleanRegion,
      'officerId': ?cleanOfficerId,
    };
    try {
      final ok = await FirestoreService.instance.updateCurrentUserProfile(data);
      if (!ok) {
        debugPrint('updateProfile: Firestore/Backend write failed');
      }
      return ok;
    } catch (e) {
      debugPrint('updateProfile: error saving to Firestore: $e');
      return false;
    }
  }

  static String? _cleanOptional(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '-') return null;
    return trimmed;
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
