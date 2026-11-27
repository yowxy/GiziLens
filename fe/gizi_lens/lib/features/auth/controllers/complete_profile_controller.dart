import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/firebase_auth_service.dart';
import '../../../core/services/user_session_service.dart';
import '../models/officer_profile_model.dart';
import '../models/officer_role.dart';

/// Controller handling state and interactions for the Complete Profile screen.
class CompleteProfileController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController fullNameController;
  final TextEditingController unitController = TextEditingController();
  final TextEditingController regionController = TextEditingController();

  OfficerProfileModel _profile = OfficerProfileModel.initial();
  bool _isLoading = false;
  String? _errorMessage;

  OfficerProfileModel get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OfficerRole get selectedRole => _profile.selectedRole;
  List<OfficerRole> get availableRoles => OfficerRole.defaultRoles;
  String get selectedUnit => unitController.text.trim();
  String get selectedRegion => regionController.text.trim();
  String get accountEmail => FirebaseAuthService.instance.currentUser?.email ?? '-';

  CompleteProfileController() {
    final user = FirebaseAuthService.instance.currentUser;
    String initialName = '';
    if (user != null) {
      _profile = _profile.copyWith(
        officerId: FirebaseAuthService.buildOfficerId(user.uid),
      );
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        initialName = user.displayName!.trim();
      } else if (user.email != null && user.email!.isNotEmpty) {
        initialName = FirebaseAuthService.formatNameFromEmail(user.email!);
      }
    }

    fullNameController = TextEditingController(text: initialName);
    fullNameController.addListener(_onNameChanged);
    if (initialName.isNotEmpty) {
      _onNameChanged();
    }
  }

  void _onNameChanged() {
    final text = fullNameController.text.trim();
    String newInitials = '-';
    if (text.isNotEmpty) {
      final parts = text.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        newInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        newInitials = parts[0][0].toUpperCase();
      }
    }
    _profile = _profile.copyWith(
      fullName: text,
      initials: newInitials,
    );
    notifyListeners();
  }

  void selectRole(OfficerRole role) {
    if (_profile.selectedRole != role) {
      _profile = _profile.copyWith(selectedRole: role);
      notifyListeners();
    }
  }

  void setPhotoPath(String path) {
    _profile = _profile.copyWith(photoPath: path);
    notifyListeners();
  }

  String? validateFullName(String? value) {
    if (value != null && value.trim().isNotEmpty && value.trim().length < 3) {
      return 'Nama lengkap terlalu pendek';
    }
    return null;
  }

  String? validateUnit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.operationalUnitRequired;
    }
    return null;
  }

  String? validateRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.regionRequired;
    }
    return null;
  }

  Future<bool> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await UserSessionService.instance.updateProfile(
        fullName: _profile.fullName,
        role: _profile.selectedRole.title,
        unit: selectedUnit,
        region: selectedRegion,
        officerId: _profile.officerId,
      );

      _isLoading = false;
      if (!ok) {
        _errorMessage = 'Gagal menyimpan data profil ke server. Periksa koneksi internet Anda.';
      }
      notifyListeners();
      return ok;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan saat menyimpan profil: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    fullNameController.removeListener(_onNameChanged);
    fullNameController.dispose();
    unitController.dispose();
    regionController.dispose();
    super.dispose();
  }
}
