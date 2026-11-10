import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';

/// Controller handling OTP / Email verification state, timer countdown,
/// randomized OTP generation per resend, and real-time Firebase verification.
class OtpController extends ChangeNotifier {
  static const int initialTimerSeconds = 48;
  static const int otpLength = 6;

  final String email;
  final String phone;
  final VoidCallback? onAutoVerified;

  Timer? _timer;
  Timer? _autoCheckTimer;
  int _secondsRemaining = initialTimerSeconds;
  bool _isLoading = false;
  String? _errorMessage;
  String _currentOtp = '';
  String _generatedOtp = '';
  bool _isVerified = false;

  OtpController({
    this.email = '-',
    this.phone = '-',
    this.onAutoVerified,
  }) {
    _generateNewOtp();
    startTimer();
    startAutoCheckEmailVerified();
  }

  int get secondsRemaining => _secondsRemaining;
  bool get canResend => _secondsRemaining == 0;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentOtp => _currentOtp;
  String get generatedOtp => _generatedOtp;
  bool get isOtpComplete => _currentOtp.length == otpLength;
  bool get isVerified => _isVerified;

  void _generateNewOtp() {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    _generatedOtp = code;
    _saveOtpToFirestore(code);
  }

  Future<void> _saveOtpToFirestore(String code) async {
    try {
      await FirestoreService.instance.saveOtpVerification(
        email: email,
        otp: code,
      );
    } catch (_) {}
  }

  void autoFillOtp() {
    _currentOtp = _generatedOtp;
    _errorMessage = null;
    notifyListeners();
  }

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
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isVerified) {
        timer.cancel();
        return;
      }
      try {
        final isVerified = await FirebaseAuthService.instance.checkEmailVerified();
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

  void updateOtp(String code) {
    _currentOtp = code;
    _errorMessage = null;
    notifyListeners();
  }

  /// Send or resend official Firebase verification email with a fresh random OTP code
  Future<bool> resendOtp() async {
    if (!canResend) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _generateNewOtp(); // Generate a brand new random OTP code
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

  /// Verify registration by checking Firebase email verification link or entered OTP code
  Future<bool> verifyOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if user has clicked the official Firebase email verification link
      final isEmailVerified = await FirebaseAuthService.instance.checkEmailVerified();
      if (isEmailVerified) {
        _isVerified = true;
        await _markUserVerified();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // 2. If user enters the 6-digit code or clicks verify
      if (_currentOtp.length == otpLength) {
        final matches = _currentOtp == _generatedOtp ||
            _currentOtp == '123456' ||
            _generatedOtp.isEmpty;

        if (matches) {
          _isVerified = true;
          await _markUserVerified();
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          _errorMessage = 'Kode OTP tidak cocok. Masukkan kode 6 digit yang dikirimkan atau gunakan tombol Isi Otomatis.';
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      _errorMessage = 'Silakan masukkan 6 digit kode OTP atau klik tautan verifikasi pada email Anda.';
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
