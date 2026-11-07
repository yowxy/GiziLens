import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/dashboard_stats_model.dart';

/// Segmented capsule filter bar for switching monitoring periods.
class PeriodFilterBar extends StatelessWidget {
  final MonitoringPeriod selectedPeriod;
  final ValueChanged<MonitoringPeriod> onPeriodChanged;

  const PeriodFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.sectionMonitoringPeriod,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFECECE5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFE2E2D9),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildTab(
                title: AppStrings.periodHariIni,
                period: MonitoringPeriod.hariIni,
              ),
              _buildTab(
                title: AppStrings.period7Hari,
                period: MonitoringPeriod.tujuhHari,
              ),
              _buildTab(
                title: AppStrings.period30Hari,
                period: MonitoringPeriod.tigaPuluhHari,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab({
    required String title,
    required MonitoringPeriod period,
  }) {
    final isSelected = selectedPeriod == period;

    return Expanded(
      child: GestureDetector(
        onTap: () => onPeriodChanged(period),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isSelected
                ? AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                  )
                : AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}
