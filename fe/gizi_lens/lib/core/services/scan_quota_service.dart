import 'package:flutter/foundation.dart';

import '../utils/wib_time.dart';
import 'firestore_service.dart';
import 'user_session_service.dart';

/// Monthly scan allowance for the signed-in account.
class ScanQuota {
  const ScanQuota({
    required this.used,
    required this.limit,
    required this.periodStart,
  });

  final int used;
  final int limit;
  final DateTime periodStart;

  bool get isExhausted => used >= limit;
  int get remaining => (limit - used).clamp(0, limit);
  double get progress => limit <= 0 ? 0 : (used / limit).clamp(0, 1).toDouble();

  /// First day of the next month, when the counter starts over.
  DateTime get periodEnd => WibTime.startOfMonthUtc(periodStart, monthsAhead: 1);
}

/// Counts inspections created in the current calendar month and compares them
/// against the plan allowance, so free accounts stop at 10 scans and premium
/// accounts at 500. The counter resets automatically when the month changes
/// because only records from the first day of the current month are counted.
class ScanQuotaService {
  ScanQuotaService._();

  static final ScanQuotaService instance = ScanQuotaService._();

  static const int freeMonthlyQuota = 10;
  static const int premiumMonthlyQuota = 500;

  Future<ScanQuota> load() async {
    final isPremium = UserSessionService.instance.account.isPremium;
    final limit = isPremium ? premiumMonthlyQuota : freeMonthlyQuota;
    final monthStart = WibTime.startOfMonthUtc(DateTime.now());

    var used = 0;
    try {
      final inspections = await FirestoreService.instance.getInspections(
        limit: 500,
      );
      used = inspections.where((inspection) {
        final created = WibTime.parseInstant(
          (inspection['scannedAt'] ?? inspection['createdDateIso'])?.toString(),
        );
        return created != null && !created.isBefore(monthStart);
      }).length;
    } catch (error) {
      debugPrint('Gagal menghitung pemakaian kuota scan: $error');
    }

    return ScanQuota(used: used, limit: limit, periodStart: monthStart);
  }
}
