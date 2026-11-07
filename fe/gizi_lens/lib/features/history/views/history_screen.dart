import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../dashboard/views/widgets/gizi_lens_bottom_nav.dart';
import '../../dashboard/views/widgets/inspection_quick_dialog.dart';
import '../controllers/history_controller.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_filter_chips.dart';
import 'widgets/history_header.dart';
import 'widgets/history_tab_bar.dart';

/// Main screen displaying the nutrition audit history and filter controls.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _handleBackTap() {
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.dashboard);
      }
    } catch (_) {}
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
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
              const SizedBox(height: 16),
              const Text(
                'Filter Lanjutan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tampilkan data spesifik berdasarkan shift audit, status kepatuhan, atau lokus SPPG.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.headerDarkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              HistoryHeader(
                onBackTap: _handleBackTap,
                onNotificationTap: () {
                  _controller.dismissNotification();
                  InspectionQuickDialog.show(context);
                },
                hasNotification: _controller.hasNotification,
                searchController: _controller.searchController,
                onClearSearch: _controller.clearSearch,
              ),

              HistoryTabBar(
                activeTab: _controller.activeTab,
                onTabChanged: _controller.setTab,
              ),

              HistoryFilterChips(
                activeDateFilter: _controller.activeDateFilter,
                onFilterChanged: _controller.setDateFilter,
                onAdvancedFilterTap: _showFilterModal,
              ),

              const Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: HistoryEmptyState(),
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: GiziLensBottomNav(
          currentIndex: 2,
          onTap: (index) {
            if (index == 0) {
              try {
                context.go(RouteNames.dashboard);
              } catch (_) {}
            } else if (index == 1) {
              try {
                context.push(RouteNames.scanOmpreng);
              } catch (_) {
                context.go(RouteNames.scanOmpreng);
              }
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
