import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../utils/wib_time.dart';
import 'backend_api_service.dart';

/// Data persistence facade for GiziLens.
///
/// Firebase Auth handles authentication and Cloud Firestore (`users/{uid}`)
/// stores officer profile metadata (`fullName`, `role`, `unit`, `region`,
/// `officerId`, `phone`, `email`). Inspections, subscriptions, and transactions
/// are persisted in PostgreSQL via [BackendApiService], which also keeps
/// organization membership synced for the admin dashboard.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final Map<String, Map<String, dynamic>> _localUserProfiles = {};
  final List<Map<String, dynamic>> _localInspections = [];

  BackendApiService get _api => BackendApiService.instance;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  User? get _currentUser {
    if (!_isFirebaseReady) return null;
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    if (!_isFirebaseReady) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // USER PROFILES
  // ==========================================

  Future<bool> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final merged = <String, dynamic>{
      ...?_localUserProfiles[uid],
      ...data,
      'uid': uid,
      'updatedAtIso': nowIso,
    };
    _localUserProfiles[uid] = merged;

    var persisted = false;

    // 1. Persist officer profile fields in Cloud Firestore (`users/{uid}`).
    final fs = _firestore;
    if (fs != null) {
      try {
        final firestorePayload = <String, dynamic>{...merged}
          ..removeWhere((_, v) => v == null);
        await fs
            .collection('users')
            .doc(uid)
            .set(firestorePayload, SetOptions(merge: true))
            .timeout(const Duration(seconds: 8));
        persisted = true;
      } catch (e) {
        debugPrint('Cloud Firestore saveUserProfile error: $e');
      }
    }

    // 2. Sync organization membership & unit/region to Backend PostgreSQL.
    try {
      final response = await _api.upsertUser(uid, merged);
      if (response != null) {
        persisted = true;
        // Keep authoritative subscription flags from backend without letting
        // backend org.name overwrite the officer's personal fullName/role.
        _localUserProfiles[uid] = {
          ...merged,
          if (response['isPremium'] != null) 'isPremium': response['isPremium'],
          if (response['subscriptionPlan'] != null)
            'subscriptionPlan': response['subscriptionPlan'],
          if (response['isVerified'] != null)
            'isVerified': response['isVerified'],
        };
      }
    } catch (e) {
      debugPrint('Backend upsertUser error: $e');
    }

    return persisted;
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    Map<String, dynamic>? firestoreData;
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 8));
        if (snap.exists && snap.data() != null) {
          firestoreData = Map<String, dynamic>.from(snap.data()!);
        }
      } catch (e) {
        debugPrint('Cloud Firestore getUserProfile error: $e');
      }
    }

    Map<String, dynamic>? backendData;
    try {
      backendData = await _api.getUserProfile(uid);
    } catch (e) {
      debugPrint('Backend getUserProfile error: $e');
    }

    final cached = _localUserProfiles[uid];
    if (firestoreData == null && backendData == null && cached == null) {
      return null;
    }

    // Merge order: cached -> backend fallback -> Cloud Firestore profile identity
    // (preserving backend subscription status when active).
    final merged = <String, dynamic>{
      ...?cached,
    };

    if (backendData != null) {
      final bUnit = backendData['unit'] as String?;
      final bRegion = backendData['region'] as String?;
      final bRole = backendData['role'] as String?;
      final bName = backendData['fullName'] as String?;
      if (bUnit != null && bUnit.trim().isNotEmpty) merged['unit'] = bUnit;
      if (bRegion != null && bRegion.trim().isNotEmpty) {
        merged['region'] = bRegion;
      }
      if (bRole != null && bRole.trim().isNotEmpty) merged['role'] ??= bRole;
      // Backend serialize_member historically used org.name as fullName; only use
      // it as fallback if distinct from unit.
      if (bName != null &&
          bName.trim().isNotEmpty &&
          bName.trim() != (bUnit ?? '').trim()) {
        merged['fullName'] ??= bName;
      }
      if (backendData['isVerified'] != null) {
        merged['isVerified'] = backendData['isVerified'];
      }
      if (backendData['isPremium'] != null) {
        merged['isPremium'] = backendData['isPremium'];
      }
      if (backendData['subscriptionPlan'] != null) {
        merged['subscriptionPlan'] = backendData['subscriptionPlan'];
      }
    }

    if (firestoreData != null) {
      for (final entry in firestoreData.entries) {
        final value = entry.value;
        if (value == null) continue;
        if (value is String && value.trim().isEmpty) continue;
        // Let backend's active premium status win if Firestore is stale false.
        if ((entry.key == 'isPremium' || entry.key == 'subscriptionPlan') &&
            merged['isPremium'] == true) {
          continue;
        }
        merged[entry.key] = value;
      }
    }

    _localUserProfiles[uid] = merged;
    return Map<String, dynamic>.from(merged);
  }

  Future<bool> updateCurrentUserProfile(Map<String, dynamic> data) async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      return await saveUserProfile(uid: user.uid, data: data);
    } catch (error) {
      debugPrint('updateCurrentUserProfile error: $error');
      return false;
    }
  }

  // ==========================================
  // AUDIT INSPECTIONS
  // ==========================================

  Future<String?> saveInspection(Map<String, dynamic> inspectionData) async {
    final user = _currentUser;
    final generatedId = 'insp-${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      ...inspectionData,
      'id': generatedId,
      'userId': user?.uid,
      'userUid': user?.uid,
      'userEmail': user?.email,
      'createdDateIso': nowIso,
    };

    _localInspections.insert(0, payload);

    final response = await _api.createInspection(payload);
    final id = response?['id'];
    if (id is String && id.isNotEmpty) {
      payload['id'] = id;
      return id;
    }
    debugPrint('Backend unavailable. Inspeksi disimpan di cache lokal: $generatedId');
    return generatedId;
  }

  Future<List<Map<String, dynamic>>> getInspections({int limit = 50}) async {
    final remote = await _api.fetchInspections(
      userId: _currentUser?.uid,
      limit: limit,
    );
    if (remote != null) {
      final mapped = remote.map(_normalizeInspection).toList();
      if (mapped.isNotEmpty) {
        _localInspections
          ..clear()
          ..addAll(mapped);
      }
      return mapped;
    }
    return List.unmodifiable(_localInspections.take(limit).toList());
  }

  Stream<List<Map<String, dynamic>>> streamInspections({int limit = 50}) async* {
    yield await getInspections(limit: limit);
  }

  Future<Map<String, int>> getDashboardStats({DateTime? since}) async {
    final summaries = await _api.fetchInspectionSummaries(
      userId: _currentUser?.uid,
      since: since?.toUtc().toIso8601String(),
      limit: 500,
    );

    final records = summaries ??
        _localInspections.where((item) {
          if (since == null) return true;
          final created = WibTime.parseInstant(
            (item['scannedAt'] ?? item['createdDateIso'])?.toString(),
          );
          return created != null && !created.isBefore(since);
        }).toList();

    var sesuai = 0;
    var tidakSesuai = 0;
    for (final item in records) {
      final status = (item['complianceStatus'] as String? ?? '').toUpperCase();
      if (status == 'SESUAI') sesuai++;
      if (status == 'TIDAK SESUAI') tidakSesuai++;
    }
    return {
      'total': records.length,
      'sesuai': sesuai,
      'tidakSesuai': tidakSesuai,
    };
  }

  /// Convert API camelCase payloads into the map shape the existing
  /// history/dashboard widgets already read.
  Map<String, dynamic> _normalizeInspection(Map<String, dynamic> item) {
    final imageUrl = _api.resolveMediaUrl(item['imageUrl'] as String?);
    return <String, dynamic>{
      ...item,
      'userId': item['userUid'],
      'createdDateIso': item['createdAt'] ?? item['scannedAt'],
      'totalNetWeight': item['totalNetWeight'],
      'components': item['components'] ?? const [],
      'nutrition': item['nutrition'] ?? const {},
      'imageUrl': imageUrl,
    };
  }
}
