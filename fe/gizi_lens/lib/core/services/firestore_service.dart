import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'backend_api_service.dart';

/// Data persistence facade for GiziLens.
///
/// Firebase is used for **authentication only**. Profiles, inspections,
/// subscriptions and transactions are stored in PostgreSQL through
/// [BackendApiService]. An in-memory cache keeps the app usable offline; it is
/// only a fallback, never the source of truth.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final Map<String, Map<String, dynamic>> _localUserProfiles = {};
  final List<Map<String, dynamic>> _localInspections = [];

  BackendApiService get _api => BackendApiService.instance;

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // USER PROFILES
  // ==========================================

  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final merged = <String, dynamic>{
      ...?_localUserProfiles[uid],
      ...data,
      'updatedAtIso': DateTime.now().toIso8601String(),
    };
    _localUserProfiles[uid] = merged;

    final response = await _api.upsertUser(uid, merged);
    if (response != null) {
      _localUserProfiles[uid] = {...merged, ...response};
    } else {
      debugPrint('Backend unavailable. Profil disimpan di cache lokal sementara.');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final response = await _api.getUserProfile(uid);
    if (response != null) {
      _localUserProfiles[uid] = {...?_localUserProfiles[uid], ...response};
      return response;
    }
    return _localUserProfiles[uid];
  }

  Future<bool> updateCurrentUserProfile(Map<String, dynamic> data) async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      await saveUserProfile(uid: user.uid, data: data);
      return true;
    } catch (error) {
      debugPrint('updateCurrentUserProfile error: $error');
      return false;
    }
  }

  /// OTP verification is handled by Firebase Authentication. Kept as a no-op
  /// so existing controllers keep compiling.
  Future<void> saveOtpVerification({
    required String email,
    required String otp,
  }) async {
    debugPrint('OTP diverifikasi oleh Firebase Auth untuk $email');
  }

  // ==========================================
  // AUDIT INSPECTIONS
  // ==========================================

  Future<String?> saveInspection(Map<String, dynamic> inspectionData) async {
    final user = _currentUser;
    final generatedId = 'insp-${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();
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
          final created = DateTime.tryParse(
            item['createdDateIso']?.toString() ?? '',
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
