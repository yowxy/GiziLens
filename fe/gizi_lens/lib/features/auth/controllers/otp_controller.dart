import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';

/// Controller handling the email-link verification state.
///
/// No code is ever generated or displayed on the device: verification happens
/// only when the user opens the email Firebase sent and clicks its link. The
/// screen polls [FirebaseAuthService.checkEmailVerified] and can also ask the
/// user to re-send the email.
class OtpController extends ChangeNotifier {
  static const int initialTimerSeconds = 48;

  final String email;
  final String phone;
  final bool isForgotPassword;
  final VoidCallback? onAutoVerified;

  Timer? _timer;
  Timer? _autoCheckTimer;
  int _secondsRemaining = initialTimerSeconds;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerified = false;

  OtpController({
    this.email = '-',
    this.phone = '-',
    this.isForgotPassword = false,
    this.onAutoVerified,
  }) {
    startTimer();
    if (!isForgotPassword) {
      startAutoCheckEmailVerified();
    }
  }

  int get secondsRemaining => _secondsRemaining;
  bool get canResend => _secondsRemaining == 0;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _isVerified;

  String get maskedEmail {
    if (email.contains('***')) return email;
    if (email.contains('@')) {
      final parts = email.split('@');
      final name = parts[0];
      final domain = parts[1];
      if (name.length > 7) {
        return '${name.substring(0, 7)}***@$domain';
      } else if (name.length > 4) {
        return '${name.substring(0, 3)}***@$domain';
      } else if (name.isNotEmpty) {
        return '${name[0]}***@$domain';
      }
    }
    return email;
  }

  String get maskedPhone {
    if (phone.contains('****')) return phone;
    if (phone.isEmpty) return '+62 812-****-789';
    final clean = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (clean.length > 7) {
      final prefix = clean.substring(0, clean.startsWith('+') ? 6 : 5);
      final suffix = clean.substring(clean.length - 3);
      return '$prefix-****-$suffix';
    }
    return phone;
  }

  void startTimer() {
    _timer?.cancel();
    _secondsRemaining = initialTimerSeconds;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
      }
    });
  }

  void startAutoCheckEmailVerified() {
    if (isForgotPassword) return;
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isVerified) {
        timer.cancel();
        return;
      }
      try {
        final isVerified = await FirebaseAuthService.instance
            .checkEmailVerified();
        if (isVerified) {
          timer.cancel();
          _isVerified = true;
          await _markUserVerified();
          notifyListeners();
          onAutoVerified?.call();
        }
      } catch (_) {}
    });
  }

  /// Send or resend the official Firebase email (verification or reset link).
  Future<bool> resendEmail() async {
    if (!canResend) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isForgotPassword) {
        await FirebaseAuthService.instance.sendPasswordResetEmail(email);
      } else {
        await FirebaseAuthService.instance.sendEmailVerification();
      }
      _isLoading = false;
      startTimer();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _markUserVerified() async {
    try {
      final user = FirebaseAuthService.instance.currentUser;
      if (user != null) {
        await FirestoreService.instance.updateCurrentUserProfile({
          'isVerified': true,
        });
      }
    } catch (_) {}
  }

  /// Check whether the user already clicked the verification link.
  Future<bool> checkVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isEmailVerified = await FirebaseAuthService.instance
          .checkEmailVerified();
      if (isEmailVerified) {
        _isVerified = true;
        await _markUserVerified();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage =
          'Email Anda belum terverifikasi. Buka email dari GiziLens dan klik '
          'tautan verifikasi, lalu coba lagi.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memverifikasi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }
}
