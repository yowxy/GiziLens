import 'package:flutter_test/flutter_test.dart';
import 'package:gizi_lens/core/services/scan_quota_service.dart';

void main() {
  group('ScanQuota', () {
    final periodStart = DateTime(2026, 11, 1);

    test('is exhausted once the used count reaches the limit', () {
      final quota = ScanQuota(used: 10, limit: 10, periodStart: periodStart);

      expect(quota.isExhausted, isTrue);
      expect(quota.remaining, 0);
      expect(quota.progress, 1.0);
    });

    test('still allows scanning below the limit', () {
      final quota = ScanQuota(used: 9, limit: 10, periodStart: periodStart);

      expect(quota.isExhausted, isFalse);
      expect(quota.remaining, 1);
      expect(quota.progress, closeTo(0.9, 0.0001));
    });

    test('remaining never goes negative when usage overshoots', () {
      final quota = ScanQuota(used: 520, limit: 500, periodStart: periodStart);

      expect(quota.remaining, 0);
      expect(quota.progress, 1.0);
    });

    test('period end points at the first day of the next month', () {
      expect(ScanQuota(used: 0, limit: 10, periodStart: periodStart).periodEnd,
          DateTime(2026, 12, 1));
      expect(
        ScanQuota(used: 0, limit: 10, periodStart: DateTime(2026, 12, 1))
            .periodEnd,
        DateTime(2027, 1, 1),
      );
    });

    test('plan allowances match the published pricing', () {
      expect(ScanQuotaService.freeMonthlyQuota, 10);
      expect(ScanQuotaService.premiumMonthlyQuota, 500);
    });
  });
}
