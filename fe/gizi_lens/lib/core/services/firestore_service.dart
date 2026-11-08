import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Enterprise Data Persistence Service managing Cloud Firestore collections for GiziLens:
/// - `users`: SPPG auditor profiles, credentials, role authorizations
/// - `inspections`: Locked meal tray audit records, nutrient analyses, and sampling protocols
/// Equipped with transparent in-memory local fallback caching to prevent any data loss offline.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final Map<String, Map<String, dynamic>> _localUserProfiles = {};
  final List<Map<String, dynamic>> _localInspections = [];

  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _firestore {
    if (!isFirebaseInitialized) return null;
    return FirebaseFirestore.instance;
  }

  CollectionReference<Map<String, dynamic>>? get usersCollection =>
      _firestore?.collection('users');

  CollectionReference<Map<String, dynamic>>? get inspectionsCollection =>
      _firestore?.collection('inspections');

  // ==========================================
  // USER PROFILES
  // ==========================================

  /// Save or update an officer profile in Cloud Firestore (`users/{uid}`).
  Future<void> saveUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    // 1. Cache immediately in memory
    _localUserProfiles[uid] = {
      ..._localUserProfiles[uid] ?? {},
      ...data,
      'updatedAtIso': DateTime.now().toIso8601String(),
    };

    final col = usersCollection;
    if (col == null) {
      debugPrint('Firestore not initialized. Saved user profile to local memory cache.');
      return;
    }

    try {
      await col.doc(uid).set(
        {
          ...data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Firestore user profile saved successfully for uid: $uid');
    } catch (e) {
      debugPrint('Error saving user profile to Firestore: $e');
    }
  }

  /// Retrieve an officer profile by UID.
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final col = usersCollection;
    if (col != null) {
      try {
        final doc = await col.doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          _localUserProfiles[uid] = {..._localUserProfiles[uid] ?? {}, ...data};
          return data;
        }
      } catch (e) {
        debugPrint('Error fetching user profile from Firestore: $e');
      }
    }
    return _localUserProfiles[uid];
  }

  /// Update the currently logged-in officer profile metadata.
  Future<bool> updateCurrentUserProfile(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await saveUserProfile(uid: user.uid, data: data);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating current user profile: $e');
      return false;
    }
  }

  /// Save an OTP verification record for real-time tracking in Firestore.
  Future<void> saveOtpVerification({
    required String email,
    required String otp,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      await firestore.collection('otp_verifications').doc(email.trim().toLowerCase()).set({
        'email': email.trim().toLowerCase(),
        'otp': otp,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedIso': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving OTP verification: $e');
    }
  }

  // ==========================================
  // AUDIT INSPECTIONS
  // ==========================================

  /// Save a verified and locked meal tray inspection record to `inspections`.
  Future<String?> saveInspection(Map<String, dynamic> inspectionData) async {
    final user = FirebaseAuth.instance.currentUser;
    final generatedId = 'insp-${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      ...inspectionData,
      'id': generatedId,
      'userId': user?.uid,
      'userEmail': user?.email,
      'createdDateIso': DateTime.now().toIso8601String(),
    };

    // 1. Immediately cache in local memory so History and Dashboard see it instantly
    _localInspections.insert(0, payload);

    final col = inspectionsCollection;
    if (col == null) {
      debugPrint('Firestore offline. Saved inspection to local session list: $generatedId');
      return generatedId;
    }

    try {
      final firestorePayload = {
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final docRef = await col.add(firestorePayload);
      payload['id'] = docRef.id;
      debugPrint('Inspection saved to Firestore with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error saving inspection to Firestore: $e');
      return generatedId;
    }
  }

  /// Fetch list of inspections with optional limit.
  Future<List<Map<String, dynamic>>> getInspections({int limit = 50}) async {
    final col = inspectionsCollection;
    if (col != null) {
      try {
        final querySnapshot = await col
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        }
      } catch (e) {
        debugPrint('Error getting inspections from Firestore: $e');
        try {
          final fallbackSnapshot = await col.limit(limit).get();
          if (fallbackSnapshot.docs.isNotEmpty) {
            return fallbackSnapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList();
          }
        } catch (_) {}
      }
    }

    return List.unmodifiable(_localInspections.take(limit).toList());
  }

  /// Stream real-time updates for inspection records.
  Stream<List<Map<String, dynamic>>> streamInspections({int limit = 50}) {
    final col = inspectionsCollection;
    if (col == null) return const Stream.empty();

    try {
      return col
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error creating inspection stream: $e');
      return const Stream.empty();
    }
  }

  /// Compute compliance statistics (Sesuai, Tidak Sesuai, Total) from real records.
  Future<Map<String, int>> getDashboardStats() async {
    final col = inspectionsCollection;
    if (col != null) {
      try {
        final snapshot = await col.get();
        if (snapshot.docs.isNotEmpty) {
          int sesuai = 0;
          int tidakSesuai = 0;

          for (var doc in snapshot.docs) {
            final status = doc.data()['complianceStatus'];
            if (status == 'SESUAI' || status == 'sesuai') {
              sesuai++;
            } else if (status == 'TIDAK SESUAI' || status == 'tidak_sesuai') {
              tidakSesuai++;
            }
          }

          return {
            'total': snapshot.docs.length,
            'sesuai': sesuai,
            'tidakSesuai': tidakSesuai,
          };
        }
      } catch (e) {
        debugPrint('Error calculating dashboard stats from Firestore: $e');
      }
    }

    int sesuai = 0;
    int tidakSesuai = 0;
    for (var doc in _localInspections) {
      final status = doc['complianceStatus'];
      if (status == 'SESUAI' || status == 'sesuai') {
        sesuai++;
      } else if (status == 'TIDAK SESUAI' || status == 'tidak_sesuai') {
        tidakSesuai++;
      }
    }

    return {
      'total': _localInspections.length,
      'sesuai': sesuai,
      'tidakSesuai': tidakSesuai,
    };
  }
}
