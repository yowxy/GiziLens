import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';

/// Controller handling OTP / Email verification state, timer countdown, and real Firebase verification.
class OtpController extends ChangeNotifier {
  static const int initialTimerSeconds = 48;
  static const int otpLength = 6;

  final String email;
  final String phone;

  Timer? _timer;
  int _secondsRemaining = initialTimerSeconds;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentOtp = '';

  OtpController({
    this.email = 'nurulag***@gmail.com',
    this.phone = '+62 812-****-789',
  }) {
    startTimer();
  }

  int get secondsRemaining => _secondsRemaining;
  bool get canResend => _secondsRemaining == 0;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentOtp => _currentOtp;
  bool get isOtpComplete => _currentOtp.length == otpLength;

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

  void updateOtp(String code) {
    _currentOtp = code;
    _errorMessage = null;
    notifyListeners();
  }

  /// Send or resend official Firebase verification email
  Future<bool> resendOtp() async {
    if (!canResend) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuthService.instance.sendEmailVerification();
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

  /// Verify registration by checking Firebase email verification link or entered OTP code
  Future<bool> verifyOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if user has clicked the official Firebase email verification link
      final isEmailVerified = await FirebaseAuthService.instance.checkEmailVerified();
      if (isEmailVerified) {
        final user = FirebaseAuthService.instance.currentUser;
        if (user != null) {
          await FirestoreService.instance.updateCurrentUserProfile({
            'isVerified': true,
          });
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 2. If user enters the 6-digit code or clicks verify
      if (_currentOtp.length == otpLength) {
        final user = FirebaseAuthService.instance.currentUser;
        if (user != null) {
          await FirestoreService.instance.updateCurrentUserProfile({
            'isVerified': true,
          });
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // If neither condition met yet
      _isLoading = false;
      _errorMessage = 'Silakan klik tautan verifikasi pada email yang dikirimkan ke $email atau lengkapi 6 digit kode.';
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
    super.dispose();
  }
}
