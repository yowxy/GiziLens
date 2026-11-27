import 'package:flutter/foundation.dart';

import '../utils/wib_time.dart';
import 'detection_api_service.dart';
import 'user_session_service.dart';

/// Monthly scan allowance for the signed-in account.
class ScanQuota {
  const ScanQuota({
    required this.used,
    required this.limit,
    required this.periodStart,
    this.available = true,
    this.reserved = 0,
  });

  final int used;
  final int limit;
  final DateTime periodStart;
  final bool available;
  final int reserved;

  bool get isExhausted =>
      available && used + reserved >= limit;

  int get remaining =>
      (limit - used - reserved).clamp(0, limit);

  double get progress =>
      limit <= 0
          ? 0
          : (used / limit).clamp(0, 1).toDouble();

  DateTime get periodEnd =>
      WibTime.startOfMonthUtc(
        periodStart,
        monthsAhead: 1,
      );
}

/// Reads authoritative usage from the backend,
/// independently of saved audits.
class ScanQuotaService {
  ScanQuotaService._();

  static final ScanQuotaService instance =
      ScanQuotaService._();

  static const int freeMonthlyQuota = 10;
  static const int premiumMonthlyQuota = 500;

  Future<ScanQuota> load() async {
    final isPremium =
        UserSessionService.instance.account.isPremium;

    final limit = isPremium
        ? premiumMonthlyQuota
        : freeMonthlyQuota;

    final monthStart =
        WibTime.startOfMonthUtc(DateTime.now());

    try {
      final data =
          await DetectionApiService().fetchQuota();

      return ScanQuota(
        used: (data['used'] as num).toInt(),
        reserved: (data['reserved'] as num).toInt(),
        limit: (data['limit'] as num).toInt(),
        periodStart: DateTime.parse(
          data['periodStart'] as String,
        ).toUtc(),
      );
    } catch (error) {
      debugPrint(
        'Gagal mengambil kuota scan: $error',
      );

      return ScanQuota(
        used: 0,
        limit: limit,
        periodStart: monthStart,
        available: false,
      );
    }
  }
}