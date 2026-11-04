import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/badge_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Image.asset(
          AppAssets.logoGiziLens,
          height: 28,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryDark),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenHorizontalPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  AppAssets.mascotLensy,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const BadgeChip(
                label: 'SPPG Cloud Connected',
                icon: Icon(
                  Icons.cloud_done_rounded,
                  size: 14,
                  color: AppColors.accentCheckGreen,
                ),
                backgroundColor: AppColors.badgeOnlineBg,
                textColor: AppColors.badgeOnlineText,
              ),
              const SizedBox(height: 12),
              Text(
                'Selamat Datang di GiziLens',
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(
                  fontSize: 22,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Aplikasi siap digunakan untuk audit mutu dan pemindaian baki makan siang MBG berbasis AI.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.checklist_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cross-Checking 4 Desain Splash:',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InspectionButton(
                      number: '01',
                      title: 'Splash Screen (Connecting)',
                      subtitle: 'Progress bar ~5% • Status sync cloud',
                      onTap: () => context.go(RouteNames.splash01),
                    ),
                    const SizedBox(height: 8),
                    _InspectionButton(
                      number: '02',
                      title: 'Splash Screen (Connected)',
                      subtitle: 'Progress bar 100% penuh • Siap transisi',
                      onTap: () => context.go(RouteNames.splash02),
                    ),
                    const SizedBox(height: 8),
                    _InspectionButton(
                      number: '03',
                      title: 'Splash Onboarding (Scan Ompreng)',
                      subtitle: 'AR Viewfinder baki 5 lauk • AI Aktif',
                      onTap: () => context.go(RouteNames.splash03),
                    ),
                    const SizedBox(height: 8),
                    _InspectionButton(
                      number: '04',
                      title: 'Splash Onboarding (Nutrisi Seimbang)',
                      subtitle: 'Skor Gizi • Energi 520 kkal • 3 Bar Nutrisi',
                      onTap: () => context.go(RouteNames.splash04),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Putar Alur Penuh (Auto Flow)',
                leadingIcon: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  context.go(RouteNames.splash);
                },
              ),
              const SizedBox(height: 14),
              Text(
                AppStrings.taglinePlain,
                style: AppTypography.caption,
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectionButton extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InspectionButton({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: AppTypography.captionBold.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
