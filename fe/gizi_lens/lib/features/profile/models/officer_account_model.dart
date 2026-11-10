class OfficerAccountModel {
  final String fullName;
  final String initials;
  final String roleTitle;
  final String officerId;
  final String unitOperational;
  final String unitRegion;
  final bool isVerified;


  const OfficerAccountModel({
    required this.fullName,
    required this.initials,
    required this.roleTitle,
    required this.officerId,
    required this.unitOperational,
    required this.unitRegion,
    this.isVerified = true,

  });

  factory OfficerAccountModel.defaultAccount() {
    return const OfficerAccountModel(
      fullName: '-',
      initials: '-',
      roleTitle: '-',
      officerId: '-',
      unitOperational: '-',
      unitRegion: '-',
      isVerified: false,

    );
  }

  OfficerAccountModel copyWith({
    String? fullName,
    String? initials,
    String? roleTitle,
    String? officerId,
    String? unitOperational,
    String? unitRegion,
    bool? isVerified,

  }) {
    return OfficerAccountModel(
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      roleTitle: roleTitle ?? this.roleTitle,
      officerId: officerId ?? this.officerId,
      unitOperational: unitOperational ?? this.unitOperational,
      unitRegion: unitRegion ?? this.unitRegion,
      isVerified: isVerified ?? this.isVerified,

    );
  }
}
