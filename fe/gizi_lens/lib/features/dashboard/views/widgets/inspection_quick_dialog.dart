import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';

/// Modal dialog providing 1-click test inspection routes to all project screens.
class InspectionQuickDialog extends StatelessWidget {
  const InspectionQuickDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const InspectionQuickDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.rule_rounded,
                color: AppColors.headerDarkGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Menu Inspeksi & Navigasi Cepat',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildItem(
            context,
            code: '01',
            title: 'Splash Screen (Connecting)',
            subtitle: 'Progress bar ~5% • Status sync cloud',
            route: RouteNames.splash01,
          ),
          _buildItem(
            context,
            code: '02',
            title: 'Splash Screen (Connected)',
            subtitle: 'Progress bar 100% penuh • Siap transisi',
            route: RouteNames.splash02,
          ),
          _buildItem(
            context,
            code: '03',
            title: 'Splash Onboarding (Scan Ompreng)',
            subtitle: 'AR Viewfinder baki 5 lauk • AI Aktif',
            route: RouteNames.splash03,
          ),
          _buildItem(
            context,
            code: '04',
            title: 'Splash Onboarding (Nutrisi Seimbang)',
            subtitle: 'Skor Gizi • Energi 520 kkal • 3 Bar Nutrisi',
            route: RouteNames.splash04,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildItem(
            context,
            code: 'A1',
            title: 'Login Petugas (1auth.png)',
            subtitle: 'Portal Resmi Auditor SPPG • Kredensial',
            route: RouteNames.login,
          ),
          _buildItem(
            context,
            code: 'A2',
            title: 'Lengkapi Profil Petugas (2auth.png)',
            subtitle: 'Verifikasi BGN • Pilih Peran Operasional',
            route: RouteNames.completeProfile,
          ),
          const Divider(color: AppColors.borderLight, height: 16),
          _buildItem(
            context,
            code: '05',
            title: 'Input Data Batch & Periksa Menu',
            subtitle: 'Langkah 1 dari 4: Data Batch • Target AKG',
            route: RouteNames.menuInspection,
          ),
          _buildItem(
            context,
            code: 'H1',
            title: 'Riwayat Pemeriksaan (history.png)',
            subtitle: 'Monitoring Gizi MBG • Status Filter & Pencarian',
            route: RouteNames.history,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required String code,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.headerDarkGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                code,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
