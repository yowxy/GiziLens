import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/history_filter_model.dart';

class HistoryFilterChips extends StatelessWidget {
  final HistoryDateFilter activeDateFilter;
  final ValueChanged<HistoryDateFilter> onFilterChanged;
  final VoidCallback onAdvancedFilterTap;

  const HistoryFilterChips({
    super.key,
    required this.activeDateFilter,
    required this.onFilterChanged,
    required this.onAdvancedFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildChip(
                    title: AppStrings.periodHariIni,
                    filter: HistoryDateFilter.hariIni,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    title: AppStrings.period7Hari,
                    filter: HistoryDateFilter.tujuhHari,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    title: AppStrings.period30Hari,
                    filter: HistoryDateFilter.tigaPuluhHari,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAdvancedFilterTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.tune_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String title,
    required HistoryDateFilter filter,
  }) {
    final isSelected = activeDateFilter == filter;

    return GestureDetector(
      onTap: () => onFilterChanged(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.badgeBg : const Color(0xFFF0EEE7),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: isSelected
              ? AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.primaryDeep,
                )
              : AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
        ),
      ),
    );
  }
}
