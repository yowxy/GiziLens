import 'dart:async';
import 'package:flutter/material.dart';

/// Controller handling 6-digit OTP verification state, timer countdown, and resend logic.
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
        return '${name.substring(0, 4)}***@$domain';
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

  Future<bool> resendOtp() async {
    if (!canResend) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate requesting new OTP token from auth server
      await Future.delayed(const Duration(milliseconds: 500));
      _isLoading = false;
      startTimer();
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal mengirim ulang kode OTP.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp() async {
    if (_currentOtp.length < otpLength) {
      _errorMessage = 'Masukkan 6 digit kode sandi OTP lengkap.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate verification against SPPG verification endpoint
      await Future.delayed(const Duration(milliseconds: 700));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Kode OTP tidak valid atau telah kedaluwarsa.';
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
