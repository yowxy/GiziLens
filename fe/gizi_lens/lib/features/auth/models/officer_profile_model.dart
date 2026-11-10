import 'officer_role.dart';

/// Data model representing the officer profile in GiziLens.
class OfficerProfileModel {
  final String fullName;
  final String officerId;
  final OfficerRole selectedRole;
  final bool isVerified;
  final bool isCertificationActive;
  final String initials;
  final String? photoPath;

  const OfficerProfileModel({
    required this.fullName,
    required this.officerId,
    required this.selectedRole,
    this.isVerified = true,
    this.isCertificationActive = true,
    this.initials = 'NG',
    this.photoPath,
  });

  factory OfficerProfileModel.initial() {
    return const OfficerProfileModel(
      fullName: '-',
      officerId: '-',
      selectedRole: OfficerRole.ahliGizi,
      isVerified: true,
      isCertificationActive: true,
      initials: '-',
    );
  }

  OfficerProfileModel copyWith({
    String? fullName,
    String? officerId,
    OfficerRole? selectedRole,
    bool? isVerified,
    bool? isCertificationActive,
    String? initials,
    String? photoPath,
  }) {
    return OfficerProfileModel(
      fullName: fullName ?? this.fullName,
      officerId: officerId ?? this.officerId,
      selectedRole: selectedRole ?? this.selectedRole,
      isVerified: isVerified ?? this.isVerified,
      isCertificationActive:
          isCertificationActive ?? this.isCertificationActive,
      initials: initials ?? this.initials,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}
