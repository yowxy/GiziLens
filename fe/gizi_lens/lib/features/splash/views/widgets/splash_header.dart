import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/badge_chip.dart';
import '../../../../core/widgets/status_dot.dart';

class SplashHeader extends StatelessWidget {
  const SplashHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StatusDot(
                color: AppColors.primaryDark,
                size: 7,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.splashHeaderLeft,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          BadgeChip(
            label: AppStrings.splashHeaderRight,
            icon: const Icon(
              Icons.verified_user_outlined,
              size: 15,
              color: AppColors.primaryDark,
            ),
            backgroundColor: AppColors.surface,
            borderColor: AppColors.borderMedium,
            textColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            textStyle: AppTypography.badge.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
