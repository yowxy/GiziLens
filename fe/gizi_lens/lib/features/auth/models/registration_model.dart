/// Model representing registration request and state.
class RegistrationModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final bool agreeTerms;
  final String role;
  final String unit;

  const RegistrationModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.agreeTerms = false,
    this.role = 'Ahli Gizi Lapangan',
    this.unit = 'SPPG Cibinong Sentral 02',
  });

  RegistrationModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    bool? agreeTerms,
    String? role,
    String? unit,
  }) {
    return RegistrationModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      agreeTerms: agreeTerms ?? this.agreeTerms,
      role: role ?? this.role,
      unit: unit ?? this.unit,
    );
  }
}
