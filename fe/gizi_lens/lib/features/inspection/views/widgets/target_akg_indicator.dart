import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/target_akg_model.dart';

/// Reusable session target AKG indicator card.
class TargetAkgIndicator extends StatelessWidget {
  final TargetAkgModel targetAkg;

  const TargetAkgIndicator({
    super.key,
    required this.targetAkg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE0E7DC),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.timer_outlined,
            size: 16,
            color: AppColors.primaryDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Text(
                  AppStrings.targetAkgSessionLabel,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  targetAkg.formattedSummary,
                  style: AppTypography.titleSmall.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
