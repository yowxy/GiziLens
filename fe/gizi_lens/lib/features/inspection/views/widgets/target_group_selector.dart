import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/target_akg_model.dart';
import 'target_akg_indicator.dart';

/// Reusable selector for target demographic group and dynamic AKG target indicators.
class TargetGroupSelector extends StatelessWidget {
  final TargetAkgModel selectedTargetAkg;
  final ValueChanged<TargetAkgModel> onTargetAkgChanged;

  const TargetGroupSelector({
    super.key,
    required this.selectedTargetAkg,
    required this.onTargetAkgChanged,
  });

  void _showAkgSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Pilih Kelompok Penerima Sasaran',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Standar Angka Kecukupan Gizi (AKG) disesuaikan secara otomatis sesuai kelompok usia penerima manfaat.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...TargetAkgModel.standardPresets.map((preset) {
                final isSelected = preset.groupName == selectedTargetAkg.groupName;
                return InkWell(
                  onTap: () {
                    onTargetAkgChanged(preset);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEAF3E9) : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryDeep : AppColors.borderLight,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.groupName,
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preset.formattedSummary,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 11.5,
                                  color: isSelected ? AppColors.primaryDeep : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryDeep,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppStrings.targetGroupLabel,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showAkgSelectorModal(context),
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.btnUbahAkg,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showAkgSelectorModal(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderMedium,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedTargetAkg.groupName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        TargetAkgIndicator(targetAkg: selectedTargetAkg),
      ],
    );
  }
}
