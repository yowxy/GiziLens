import 'package:flutter/material.dart';
import '../models/officer_profile_model.dart';
import '../models/officer_role.dart';

/// Controller handling state and interactions for the Complete Profile screen.
class CompleteProfileController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController fullNameController;

  OfficerProfileModel _profile = OfficerProfileModel.initial();
  bool _isLoading = false;

  OfficerProfileModel get profile => _profile;
  bool get isLoading => _isLoading;
  OfficerRole get selectedRole => _profile.selectedRole;
  List<OfficerRole> get availableRoles => OfficerRole.defaultRoles;

  CompleteProfileController() {
    fullNameController = TextEditingController(text: '');
    fullNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final text = fullNameController.text.trim();
    String newInitials = 'NG';
    if (text.isNotEmpty) {
      final parts = text.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        newInitials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        newInitials = parts[0][0].toUpperCase();
      }
    }
    _profile = _profile.copyWith(
      fullName: text.isEmpty ? 'Nurul Gizi' : text,
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
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
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
