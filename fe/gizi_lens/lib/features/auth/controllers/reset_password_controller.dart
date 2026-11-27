import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/firebase_auth_service.dart';

/// Controller handling the final step of password recovery: validating the
/// reset code from the official Firebase email and setting a new password.
class ResetPasswordController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
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

  String? validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kode reset wajib diisi';
    }
    if (FirebaseAuthService.extractOobCode(value).length < 10) {
      return 'Kode reset tidak valid. Salin tautan reset lengkap dari email.';
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

  /// Paste the reset link/code currently held in the clipboard.
  Future<bool> pasteCodeFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) return false;
      codeController.text = text;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submit() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuthService.instance.confirmPasswordReset(
        resetCode: codeController.text.trim(),
        newPassword: passwordController.text,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
