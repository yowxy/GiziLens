import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/badge_chip.dart';
import '../../../../core/widgets/scan_frame_border.dart';
import '../../../../core/widgets/status_dot.dart';

class PageScanOmpreng extends StatelessWidget {
  const PageScanOmpreng({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF0EEDB).withValues(alpha: 0.8),
                        AppColors.background.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 36,
                  child: Icon(
                    Icons.filter_vintage_outlined,
                    size: 24,
                    color: AppColors.primaryDark.withValues(alpha: 0.22),
                  ),
                ),
                Image.asset(
                  AppAssets.mascotLensy,
                  height: 140,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  bottom: 4,
                  child: BadgeChip(
                    label: AppStrings.aiAktif,
                    icon: const StatusDot(
                      color: AppColors.accentGold,
                      size: 7,
                    ),
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.borderLight,
                    textColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    textStyle: AppTypography.badge.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ScanViewfinderFrame(
            bracketColor: AppColors.primaryDark,
            bracketLength: 16,
            bracketThickness: 2.4,
            cornerRadius: 4,
            padding: const EdgeInsets.all(6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 11,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  AppAssets.foodNasiPutih,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          AppStrings.foodNasiPutih,
                                          style: AppTypography.titleSmall.copyWith(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: AppColors.accentCheckGreen,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      AppStrings.foodNasiNutrisi,
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 9.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Container(
                                        height: 3.5,
                                        width: 80,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 9,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  AppAssets.foodTelurBalado,
                                  width: double.infinity,
                                  height: 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.foodTelurBalado,
                                style: AppTypography.titleSmall.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              Text(
                                AppStrings.foodTelurNutrisi,
                                style: AppTypography.caption.copyWith(
                                  fontSize: 9.5,
                                  color: AppColors.accentAmber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _FoodMiniCard(
                          imagePath: AppAssets.foodSayurBayam,
                          title: AppStrings.foodSayurBayam,
                          subtitle: AppStrings.foodSayurNutrisi,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _FoodMiniCard(
                          imagePath: AppAssets.foodTempeOrek,
                          title: AppStrings.foodTempeOrek,
                          subtitle: AppStrings.foodTempeNutrisi,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _FoodMiniCard(
                          imagePath: AppAssets.foodPisangMas,
                          title: AppStrings.foodPisangMas,
                          subtitle: AppStrings.foodPisangNutrisi,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.borderLight, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.standarGiziMbg,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          AppStrings.kkal465,
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          BadgeChip(
            label: AppStrings.onboarding1Badge,
            icon: const Icon(
              Icons.camera_alt_outlined,
              size: 15,
              color: AppColors.badgeText,
            ),
            backgroundColor: AppColors.badgeBg,
            textColor: AppColors.badgeText,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.onboarding1Title,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppStrings.onboarding1Desc,
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

class _FoodMiniCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const _FoodMiniCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 28,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              fontSize: 8.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
