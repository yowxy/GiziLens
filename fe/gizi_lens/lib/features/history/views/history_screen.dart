import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../core/utils/wib_time.dart';
import '../../dashboard/views/widgets/gizi_lens_bottom_nav.dart';
import '../../notifications/views/notification_sheet.dart';
import '../controllers/history_controller.dart';
import 'history_detail_screen.dart';
import 'widgets/annotated_scan_image.dart';
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
                onNotificationTap: () => showNotificationSheet(context),
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

              Expanded(
                child: _controller.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryDeep),
                      )
                    : _controller.filteredInspections.isEmpty
                        ? const SingleChildScrollView(
                            physics: BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            child: HistoryEmptyState(),
                          )
                        : RefreshIndicator(
                            color: AppColors.primaryDeep,
                            onRefresh: _controller.loadInspections,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: _controller.filteredInspections.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final item = _controller.filteredInspections[idx];
                                return _buildInspectionCard(item, idx);
                              },
                            ),
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
                context.push(RouteNames.menuInspection);
              } catch (_) {
                context.go(RouteNames.menuInspection);
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

  Widget _buildInspectionCard(Map<String, dynamic> item, int index) {
    final batchCode = item['batchCode'] as String? ?? '-';
    final schoolName = item['schoolName'] as String? ?? '-';
    final isSesuai =
        (item['complianceStatus'] as String? ?? '').toUpperCase() == 'SESUAI';
    final components = _components(item);
    final kcal = _totalCalories(item, components);
    final menuTitle = 'Menu Gizi Seimbang #${index + 1}';
    final description = _componentNames(components);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HistoryDetailScreen(item: item)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2ECE0), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 14,
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
                  Icons.event_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatDateTime(item),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                _statusPill(isSesuai),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  batchCode,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '•',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    schoolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnnotatedScanImage(
                  imageUrl: item['imageUrl'] as String?,
                  components: components,
                  width: 88,
                  height: 88,
                  borderRadius: BorderRadius.circular(14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menuTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description.isEmpty ? 'Belum ada komponen' : description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _infoChip(
                            icon: Icons.layers_outlined,
                            label: '${components.length} Komponen',
                          ),
                          _infoChip(
                            icon: Icons.local_fire_department_outlined,
                            label: '${_formatNumber(kcal)} kkal',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEF3ED)),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  isSesuai
                      ? Icons.verified_outlined
                      : Icons.error_outline_rounded,
                  size: 15,
                  color: isSesuai
                      ? AppColors.statSesuaiGreen
                      : AppColors.statTidakSesuaiRed,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isSesuai ? 'Standar MBG Terpenuhi' : 'Perlu Tinjauan Ahli Gizi',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isSesuai
                          ? AppColors.statSesuaiGreen
                          : AppColors.statTidakSesuaiRed,
                    ),
                  ),
                ),
                const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.primaryDeep,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(bool isSesuai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isSesuai ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSesuai ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 12,
            color: isSesuai ? const Color(0xFF15803D) : const Color(0xFFE11D48),
          ),
          const SizedBox(width: 4),
          Text(
            isSesuai ? 'Sesuai' : 'Tidak Sesuai',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isSesuai ? const Color(0xFF15803D) : const Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE4EBE0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _components(Map<String, dynamic> item) {
    final raw = item['components'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static String _componentNames(List<Map<String, dynamic>> components) {
    return components
        .take(3)
        .map((component) => component['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  static num _totalCalories(
    Map<String, dynamic> item,
    List<Map<String, dynamic>> components,
  ) {
    final nutrition = item['nutrition'];
    if (nutrition is Map) {
      final kalori = nutrition['Kalori'];
      if (kalori is Map && kalori['currentValue'] is num) {
        return kalori['currentValue'] as num;
      }
    }
    num total = 0;
    for (final component in components) {
      final value = component['nutrition'];
      if (value is Map && value['calories'] is num) {
        total += value['calories'] as num;
      }
    }
    return total;
  }

  static String _formatNumber(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  static String _formatDateTime(Map<String, dynamic> item) {
    final iso = (item['scannedAt'] ?? item['createdDateIso']) as String?;
    final date = WibTime.parseInstant(iso);
    if (date == null) return '-';
    final local = WibTime.calendar(date);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)} ${months[local.month - 1]} ${local.year} '
        '• ${two(local.hour)}.${two(local.minute)} WIB';
  }
}
