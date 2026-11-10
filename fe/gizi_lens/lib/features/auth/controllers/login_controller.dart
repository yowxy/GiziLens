import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/user_session_service.dart';

/// Controller handling the state and interactions for the Login screen with Firebase.
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

  bool get isProfileIncomplete => _profileIncomplete;
  bool _profileIncomplete = false;

  /// Check whether the logged-in user has a complete profile in Firestore
  /// (role, unit, region all filled). Sets [_profileIncomplete] accordingly.
  Future<void> _checkProfileComplete() async {
    final user = FirebaseAuthService.instance.currentUser;
    if (user == null) {
      _profileIncomplete = false;
      return;
    }

    final profileData = await FirestoreService.instance.getUserProfile(user.uid);
    if (profileData == null) {
      _profileIncomplete = true;
      return;
    }

    final role = (profileData['role'] as String?)?.trim() ?? '';
    final unit = (profileData['unit'] as String?)?.trim() ?? '';
    final region = (profileData['region'] as String?)?.trim() ?? '';

    _profileIncomplete = role.isEmpty || unit.isEmpty || region.isEmpty;
  }

  Future<bool> login() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final input = emailOrIdController.text.trim();
      final password = passwordController.text;

      // Handle email or convert plain ID to institutional format
      final email = input.contains('@') ? input : '$input@gizilens.bgn.go.id';

      final credential = await FirebaseAuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After successful login, load the full profile from Firestore into
      // the session service and determine if profile completion is needed.
      if (credential != null) {
        await UserSessionService.instance.initializeFromFirebase();
        await _checkProfileComplete();
      }

      _isLoading = false;
      notifyListeners();
      return credential != null || !FirebaseAuthService.instance.isFirebaseInitialized;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
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
