import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

/// Enterprise-grade Authentication Service connecting GiziLens with Firebase Authentication.
class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _auth {
    if (!isFirebaseInitialized) return null;
    return FirebaseAuth.instance;
  }

  User? get currentUser => _auth?.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<User?> get authStateChanges {
    if (_auth == null) return const Stream.empty();
    return _auth!.authStateChanges();
  }

  /// Sign up a new SPPG officer with Email & Password.
  /// Automatically writes initial profile metadata to Cloud Firestore.
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'Ahli Gizi Lapangan',
    String unit = 'SPPG Cibinong Sentral 02',
  }) async {
    final auth = _auth;
    if (auth == null) {
      debugPrint('FirebaseAuth not initialized. Operating in fallback mode.');
      return null;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Update user display name in Firebase Auth
        await user.updateDisplayName(fullName.trim());

        // Save complete profile metadata in Cloud Firestore
        await FirestoreService.instance.saveUserProfile(
          uid: user.uid,
          data: {
            'fullName': fullName.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'role': role,
            'unit': unit,
            'officerId': 'BGN-2024-${user.uid.substring(0, 5).toUpperCase()}',
            'isVerified': true,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth signUp error: ${e.code} - ${e.message}');
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected signUp error: $e');
      throw 'Terjadi kesalahan sistem saat mendaftar: ${e.toString()}';
    }
  }

  /// Sign in an existing SPPG officer with Email & Password.
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      debugPrint('FirebaseAuth not initialized. Operating in fallback mode.');
      return null;
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Verify or ensure user document exists in Firestore
      final user = credential.user;
      if (user != null) {
        final profile = await FirestoreService.instance.getUserProfile(user.uid);
        if (profile == null) {
          // Initialize basic profile if first time or missing
          await FirestoreService.instance.saveUserProfile(
            uid: user.uid,
            data: {
              'fullName': user.displayName ?? 'Petugas SPPG',
              'email': user.email ?? email.trim(),
              'role': 'Ahli Gizi Lapangan',
              'unit': 'SPPG Cibinong Sentral 02',
              'officerId': 'BGN-2024-${user.uid.substring(0, 5).toUpperCase()}',
              'isVerified': true,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth signIn error: ${e.code} - ${e.message}');
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      debugPrint('Unexpected signIn error: $e');
      throw 'Terjadi kesalahan sistem saat masuk: ${e.toString()}';
    }
  }

  /// Send password reset link to officer email.
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) return;

    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'Gagal mengirim email reset kata sandi: ${e.toString()}';
    }
  }

  /// Sign out current officer from Firebase.
  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
  }

  /// Translate Firebase technical error codes into user-friendly Indonesian messages.
  String getFriendlyErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Akun dengan email ini belum terdaftar di sistem BGN.';
        case 'wrong-password':
          return 'Kata sandi yang Anda masukkan salah.';
        case 'invalid-credential':
          return 'Email atau kata sandi tidak cocok. Silakan periksa kembali.';
        case 'email-already-in-use':
          return 'Email ini sudah terdaftar. Silakan gunakan email lain atau masuk.';
        case 'invalid-email':
          return 'Format alamat email tidak valid.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah. Gunakan minimal 6 karakter kombinasi.';
        case 'user-disabled':
          return 'Akun petugas ini telah dinonaktifkan oleh administrator.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
        case 'network-request-failed':
          return 'Gagal terhubung ke server Firebase. Periksa koneksi internet Anda.';
        case 'operation-not-allowed':
          return 'Metode autentikasi email belum diaktifkan di Firebase Console.';
        default:
          return error.message ?? 'Terjadi kesalahan autentikasi (${error.code}).';
      }
    }
    return error.toString();
  }
}
