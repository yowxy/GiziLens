import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

/// Reusable compliance status card (SESUAI or TIDAK SESUAI) with custom badges.
class AkgStatCard extends StatelessWidget {
  final String title;
  final int count;
  final String pillText;
  final Color primaryColor;
  final Color pillBgColor;
  final Color pillTextColor;
  final VoidCallback? onTap;

  const AkgStatCard({
    super.key,
    required this.title,
    required this.count,
    required this.pillText,
    required this.primaryColor,
    required this.pillBgColor,
    required this.pillTextColor,
    this.onTap,
  });

  factory AkgStatCard.sesuai({
    int count = 0,
    VoidCallback? onTap,
  }) {
    return AkgStatCard(
      title: AppStrings.cardSesuaiTitle,
      count: count,
      pillText: AppStrings.cardSesuaiPill,
      primaryColor: AppColors.statSesuaiGreen,
      pillBgColor: AppColors.verifiedBgnBg,
      pillTextColor: AppColors.statSesuaiGreen,
      onTap: onTap,
    );
  }

  factory AkgStatCard.tidakSesuai({
    int count = 0,
    VoidCallback? onTap,
  }) {
    return AkgStatCard(
      title: AppStrings.cardTidakSesuaiTitle,
      count: count,
      pillText: AppStrings.cardTidakSesuaiPill,
      primaryColor: AppColors.statTidakSesuaiRed,
      pillBgColor: AppColors.badgeTidakSesuaiBg,
      pillTextColor: AppColors.badgeTidakSesuaiText,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderCard,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionBold.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: primaryColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$count',
                  style: AppTypography.h1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.labelSesi,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: pillBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pillText,
                style: AppTypography.captionBold.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: pillTextColor,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
