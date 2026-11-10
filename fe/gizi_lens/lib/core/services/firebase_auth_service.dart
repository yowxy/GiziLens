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

  /// Formats a human-readable officer name from an email address or username.
  static String formatNameFromEmail(String email) {
    if (email.isEmpty) return 'Petugas SPPG';
    final prefix = email.split('@').first.trim();
    if (prefix.toLowerCase() == 'iklilnajmi') {
      return 'Iklil Najmi';
    }
    final words = prefix.split(RegExp(r'[._-]+')).where((w) => w.isNotEmpty).toList();
    if (words.length > 1) {
      return words
          .map((w) => w.length > 1 ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w.toUpperCase())
          .join(' ');
    } else if (words.length == 1) {
      final w = words.first;
      final spaced = w.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
      if (spaced.contains(' ')) {
        return spaced;
      }
      return w.length > 1 ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : w.toUpperCase();
    }
    return prefix;
  }

  static String buildOfficerId(String uid) {
    final suffix = uid.length >= 5 ? uid.substring(0, 5) : uid;
    return 'BGN-${DateTime.now().year}-${suffix.toUpperCase()}';
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

        // Send official Firebase email verification directly to user's real email
        try {
          await user.sendEmailVerification();
          debugPrint('Official Firebase verification email sent to ${user.email}');
        } catch (e) {
          debugPrint('Error sending email verification: $e');
        }

        // Save complete profile metadata in Cloud Firestore
        await FirestoreService.instance.saveUserProfile(
          uid: user.uid,
          data: {
            'fullName': fullName.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'role': role,
            'unit': unit,
            'officerId': buildOfficerId(user.uid),
            'isVerified': false,
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
        final derivedName = (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!.trim()
            : formatNameFromEmail(user.email ?? email.trim());

        if (user.displayName == null || user.displayName!.trim().isEmpty) {
          try {
            await user.updateDisplayName(derivedName);
          } catch (_) {}
        }

        if (profile == null) {
          // Initialize basic profile if first time or missing
          await FirestoreService.instance.saveUserProfile(
            uid: user.uid,
            data: {
              'fullName': derivedName,
              'email': user.email ?? email.trim(),
              'role': 'Ahli Gizi Lapangan',
              'unit': 'SPPG Ketintang',
              'officerId': buildOfficerId(user.uid),
              'isVerified': true,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
        } else if (profile['fullName'] == 'Petugas SPPG' || (profile['fullName'] as String? ?? '').trim().isEmpty) {
          await FirestoreService.instance.updateCurrentUserProfile({
            'fullName': derivedName,
          });
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

  /// Send or resend official Firebase email verification link to current user.
  Future<bool> sendEmailVerification() async {
    final user = _auth?.currentUser;
    if (user != null) {
      try {
        await user.sendEmailVerification();
        debugPrint('Firebase verification email successfully sent to ${user.email}');
        return true;
      } on FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuth sendEmailVerification error: ${e.code} - ${e.message}');
        throw getFriendlyErrorMessage(e);
      } catch (e) {
        debugPrint('Error sending verification email: $e');
        throw 'Gagal mengirim email verifikasi: ${e.toString()}';
      }
    }
    return false;
  }

  /// Reload user and check if email is verified.
  Future<bool> checkEmailVerified() async {
    final user = _auth?.currentUser;
    if (user != null) {
      try {
        await user.reload();
        return _auth!.currentUser!.emailVerified;
      } catch (e) {
        debugPrint('Error reloading user: $e');
      }
    }
    return false;
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
