import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/dashboard_controller.dart';
import 'widgets/akg_stat_card.dart';
import 'widgets/akg_summary_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/gizi_lens_bottom_nav.dart';
import 'widgets/hero_menu_card.dart';
import '../../notifications/views/notification_sheet.dart';
import 'widgets/period_filter_bar.dart';

/// Dashboard screen presenting compliance metrics, period filters, and quick actions.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _showAkgInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.headerDarkGreen,
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              'Standar Kepatuhan AKG',
              style: AppTypography.titleLarge.copyWith(fontSize: 15),
            ),
          ],
        ),
        content: Text(
          'Rekapitulasi kepatuhan Angka Kecukupan Gizi (AKG) dihitung dari hasil inspeksi AI terhadap 5 pilar makanan (Pokok, Lauk Hewani, Lauk Nabati, Sayur, dan Buah). Defisit porsi >15% akan diklasifikasikan sebagai Tidak Sesuai.',
          style: AppTypography.bodyMedium.copyWith(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScanOmprengTap() {
    context.push(RouteNames.menuInspection);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundSplash,
        body: Column(
          children: [
            DashboardHeader(
              greeting: _controller.greeting,
              officerName: _controller.officerName,
              unitName: _controller.unitName,
              hasNotification: _controller.hasUnreadNotifications,
              onNotificationTap: () => showNotificationSheet(context),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSplash,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenHorizontalPadding,
                    vertical: 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeroMenuCard(
                            onInspectTap: _handleScanOmprengTap,
                          ),
                          const SizedBox(height: 22),

                          PeriodFilterBar(
                            selectedPeriod: _controller.selectedPeriod,
                            onPeriodChanged: _controller.setPeriod,
                          ),
                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Text(
                                AppStrings.sectionAkgSummary,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _showAkgInfoDialog,
                                borderRadius: BorderRadius.circular(999),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    size: 17,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          AkgSummaryCard(
                            totalCount: _controller.stats.totalDiperiksa,
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: AkgStatCard.sesuai(
                                  count: _controller.stats.totalSesuai,
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AkgStatCard.tidakSesuai(
                                  count: _controller.stats.totalTidakSesuai,
                                  onTap: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: GiziLensBottomNav(
          currentIndex: _controller.activeNavIndex,
          onTap: (index) {
            _controller.setNavIndex(index);
            if (index == 1) {
              _handleScanOmprengTap();
            } else if (index == 2) {
              try {
                context.go(RouteNames.history);
              } catch (_) {}
            } else if (index == 3) {
              try {
                context.go(RouteNames.profile);
              } catch (_) {}
            }
          },
        ),
      ),
    );
  }
}
