import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/history_filter_model.dart';

// Three category tabs for switching history view (Semua, Sesuai, Tidak Sesuai)
class HistoryTabBar extends StatelessWidget {
  final HistoryTab activeTab;
  final ValueChanged<HistoryTab> onTabChanged;

  const HistoryTabBar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE6EAE2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(
            title: AppStrings.tabSemua,
            tab: HistoryTab.semua,
          ),
          _buildTabItem(
            title: AppStrings.tabSesuai,
            tab: HistoryTab.sesuai,
          ),
          _buildTabItem(
            title: AppStrings.tabTidakSesuai,
            tab: HistoryTab.tidakSesuai,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required HistoryTab tab,
  }) {
    final isSelected = activeTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.headerDarkGreen : Colors.transparent,
                width: 3.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: isSelected
                ? AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  )
                : AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}
