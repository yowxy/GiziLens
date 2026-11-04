/// Operational roles model for SPPG/BGN officers.
class OfficerRole {
  final String id;
  final String title;
  final String description;

  const OfficerRole({
    required this.id,
    required this.title,
    required this.description,
  });

  static const OfficerRole ahliGizi = OfficerRole(
    id: 'ahli_gizi',
    title: 'Ahli Gizi Lapangan',
    description: 'Penyusun menu, kalibrasi ompreng & evaluator mutu gizi',
  );

  static const OfficerRole petugasSppg = OfficerRole(
    id: 'petugas_sppg',
    title: 'Petugas SPPG',
    description: 'Auditor porsi fisik, penimbangan real-time & tagging AI',
  );

  static const OfficerRole penyeliaDapur = OfficerRole(
    id: 'penyelia_dapur',
    title: 'Penyelia Dapur / Koordinator Lapangan',
    description:
        'Supervisi alur distribusi, verifikasi higienitas & rekapitulasi data porsi',
  );

  static const List<OfficerRole> defaultRoles = [
    ahliGizi,
    petugasSppg,
    penyeliaDapur,
  ];
}
