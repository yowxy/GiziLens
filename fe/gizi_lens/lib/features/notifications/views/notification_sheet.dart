import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/notification_service.dart';
import '../../history/views/history_detail_screen.dart';

Future<void> showNotificationSheet(BuildContext context) {
  NotificationService.instance.markAllRead();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => ListenableBuilder(
      listenable: NotificationService.instance,
      builder: (context, _) => _NotificationSheetContent(parentContext: context),
    ),
  );
}

class _NotificationSheetContent extends StatelessWidget {
  const _NotificationSheetContent({required this.parentContext});

  final BuildContext parentContext;

  @override
  Widget build(BuildContext context) {
    final service = NotificationService.instance;
    final alerts = service.alerts;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi Defisit Porsi',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            if (!service.enabled)
              _message('Notifikasi defisit porsi sedang dinonaktifkan. Aktifkan lagi di halaman Profil.')
            else if (alerts.isEmpty)
              _message('Belum ada pemeriksaan dengan defisit porsi lebih dari 15%.')
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _alertTile(alerts[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
    );
  }

  Widget _alertTile(Map<String, dynamic> item) {
    final deficits = _deficitLabels(item);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(parentContext).push(
        MaterialPageRoute(builder: (_) => HistoryDetailScreen(item: item)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF5C2C7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.statTidakSesuaiRed, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['schoolName'] as String? ?? '-',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item['batchCode'] ?? '-'} • ${item['session'] ?? '-'}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deficits.isEmpty
                        ? 'Ada komponen di bawah target AKG.'
                        : 'Di bawah target: ${deficits.join(', ')}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.statTidakSesuaiRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _deficitLabels(Map<String, dynamic> item) {
    final nutrition = item['nutrition'];
    if (nutrition is! Map) return const [];
    return nutrition.entries
        .where((entry) {
          final metric = entry.value;
          return metric is Map &&
              metric['percentageOfTarget'] is num &&
              (metric['percentageOfTarget'] as num) < 85;
        })
        .map((entry) => '${entry.key} ${(entry.value as Map)['percentageOfTarget']}%')
        .toList();
  }
}
