import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../models/operational_options.dart';
import '../models/officer_profile_model.dart';
import '../models/officer_role.dart';

/// Controller handling state and interactions for the Complete Profile screen.
class CompleteProfileController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController fullNameController;

  OfficerProfileModel _profile = OfficerProfileModel.initial();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedUnit;
  String? _selectedRegion;

  OfficerProfileModel get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OfficerRole get selectedRole => _profile.selectedRole;
  List<OfficerRole> get availableRoles => OfficerRole.defaultRoles;
  String? get selectedUnit => _selectedUnit;
  String? get selectedRegion => _selectedRegion;
  List<String> get availableUnits => OperationalOptions.sppgUnits;
  List<String> get availableRegions => OperationalOptions.regions;
  String get accountEmail => FirebaseAuthService.instance.currentUser?.email ?? '-';

  void selectUnit(String? unit) {
    _selectedUnit = unit;
    notifyListeners();
  }

  void selectRegion(String? region) {
    _selectedRegion = region;
    notifyListeners();
  }

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
        unit: _selectedUnit,
        region: _selectedRegion,
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
    super.dispose();
  }
}
