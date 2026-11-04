import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/badge_chip.dart';
import '../../../../core/widgets/status_dot.dart';

class PageNutrisiSeimbang extends StatelessWidget {
  const PageNutrisiSeimbang({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 20,
                  child: Image.asset(
                    AppAssets.mascotLensy,
                    height: 155,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.badgeOnlineBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.ramen_dining_outlined,
                            size: 16,
                            color: AppColors.accentCheckGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.skorGizi,
                              style: AppTypography.caption.copyWith(
                                fontSize: 9.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              AppStrings.lengkapDanSehat,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              size: 13,
                              color: AppColors.accentGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.energiOptimal,
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: const Color(0xFFB1D8C1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.kkal520,
                          style: AppTypography.h3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const StatusDot(
                          color: AppColors.accentGold,
                          size: 8,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.plateCompositionTitle,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    BadgeChip(
                      label: AppStrings.plateIdealBadge,
                      backgroundColor: AppColors.badgeIdealBg,
                      textColor: AppColors.badgeIdealText,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      textStyle: AppTypography.badge.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.badgeIdealText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _NutrientProgressBar(
                        label: AppStrings.karbo,
                        percentage: AppStrings.karboPct,
                        progress: 0.55,
                        barColor: AppColors.primaryDark,
                        trackColor: const Color(0xFFE5EDE7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NutrientProgressBar(
                        label: AppStrings.protein,
                        percentage: AppStrings.proteinPct,
                        progress: 0.25,
                        barColor: AppColors.accentAmber,
                        trackColor: const Color(0xFFF7EFE4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NutrientProgressBar(
                        label: AppStrings.serat,
                        percentage: AppStrings.seratPct,
                        progress: 0.20,
                        barColor: AppColors.accentOlive,
                        trackColor: const Color(0xFFEBEFEA),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          BadgeChip(
            label: AppStrings.onboarding2Badge,
            icon: const Icon(
              Icons.psychology_outlined,
              size: 15,
              color: AppColors.badgeText,
            ),
            backgroundColor: AppColors.badgeBg,
            textColor: AppColors.badgeText,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.onboarding2Title,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              AppStrings.onboarding2Desc,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NutrientProgressBar extends StatelessWidget {
  final String label;
  final String percentage;
  final double progress;
  final Color barColor;
  final Color trackColor;

  const _NutrientProgressBar({
    required this.label,
    required this.percentage,
    required this.progress,
    required this.barColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                percentage,
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5.5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: trackColor,
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      color: barColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
