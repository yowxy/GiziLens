import 'package:flutter/material.dart';
import '../models/registration_model.dart';

/// Controller handling registration flow, state, and client-side validation.
class RegisterController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get agreeTerms => _agreeTerms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void setAgreeTerms(bool value) {
    _agreeTerms = value;
    notifyListeners();
  }

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi';
    }
    if (value.trim().length < 3) {
      return 'Nama lengkap minimal 3 karakter';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid (cth. nama@email.com)';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor HP wajib diisi';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^(\+62|62|08)[0-9]{8,13}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Nomor HP tidak valid (cth. +628123456789 atau 08123456789)';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi';
    }
    if (value.length < 8) {
      return 'Kata sandi minimal 8 karakter';
    }
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigits = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetters || !hasDigits) {
      return 'Kombinasikan huruf dan angka';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi';
    }
    if (value != passwordController.text) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    return null;
  }

  bool get isFormFilled {
    return fullNameController.text.trim().isNotEmpty &&
        emailController.text.trim().isNotEmpty &&
        phoneController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        _agreeTerms;
  }

  Future<RegistrationModel?> register() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }
    if (!_agreeTerms) {
      _errorMessage = 'Anda harus menyetujui Syarat dan Ketentuan.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate account registration dispatch to SPPG BGN cloud API
      await Future.delayed(const Duration(milliseconds: 650));
      _isLoading = false;
      notifyListeners();

      return RegistrationModel(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
        agreeTerms: _agreeTerms,
        role: 'Ahli Gizi Lapangan',
        unit: 'SPPG Cibinong Sentral 02',
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal mendaftar akun: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
