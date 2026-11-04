import 'package:flutter/material.dart';

/// Controller handling the state and interactions for the Login screen (1auth).
class LoginController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailOrIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  String? validateEmailOrId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau ID Petugas tidak boleh kosong';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  Future<bool> login() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate enterprise authentication against SPPG BGN Cloud
      await Future.delayed(const Duration(milliseconds: 700));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan saat memproses login: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    emailOrIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
