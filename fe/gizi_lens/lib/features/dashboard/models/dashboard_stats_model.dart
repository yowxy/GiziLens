/// Enum representing the monitoring filter periods.
enum MonitoringPeriod {
  hariIni,
  tujuhHari,
  tigaPuluhHari,
}

/// Model holding compliance and session metrics for the dashboard.
class DashboardStatsModel {
  final int totalDiperiksa;
  final int totalSesuai;
  final int totalTidakSesuai;
  final MonitoringPeriod period;

  const DashboardStatsModel({
    this.totalDiperiksa = 0,
    this.totalSesuai = 0,
    this.totalTidakSesuai = 0,
    this.period = MonitoringPeriod.hariIni,
  });

  DashboardStatsModel copyWith({
    int? totalDiperiksa,
    int? totalSesuai,
    int? totalTidakSesuai,
    MonitoringPeriod? period,
  }) {
    return DashboardStatsModel(
      totalDiperiksa: totalDiperiksa ?? this.totalDiperiksa,
      totalSesuai: totalSesuai ?? this.totalSesuai,
      totalTidakSesuai: totalTidakSesuai ?? this.totalTidakSesuai,
      period: period ?? this.period,
    );
  }
}
