import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/services/user_session_service.dart';
import '../controllers/pricing_controller.dart';
import '../models/pricing_plan_model.dart';
import '../services/midtrans_sandbox_service.dart';
import 'widgets/bundle_card.dart';

class PricingScreen extends StatefulWidget {
  final PricingPlanModel? initialPlan;

  const PricingScreen({super.key, this.initialPlan});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  late final PricingController _controller;
  late final Map<String, GlobalKey> _cardKeys;

  @override
  void initState() {
    super.initState();
    _controller = PricingController();
    _cardKeys = {for (final p in _controller.plans) p.id: GlobalKey()};
    if (widget.initialPlan != null) {
      _controller.selectPlan(widget.initialPlan!);
    }
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _selectAndScrollToPlan(int index) {
    _controller.selectIndex(index);
    final planId = _controller.plans[index].id;
    final ctx = _cardKeys[planId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _handleProceedToCheckout() {
    context.push(RouteNames.checkout, extra: _controller.selectedPlan);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _controller.selectedPlan;

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
            // Top App Bar
            _buildAppBar(context),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Intro
                        _buildHeroIntro(),
                        const SizedBox(height: 24),

                        // Active plan banner if already subscribed
                        if (UserSessionService.instance.account.isPremium) ...[
                          _buildActiveSubscriptionBanner(),
                          const SizedBox(height: 16),
                        ],

                        // Tab Selection Pills
                        _buildPlanTabs(),
                        const SizedBox(height: 20),

                        // Bundling Cards
                        ..._controller.plans.map(
                          (plan) => KeyedSubtree(
                            key: _cardKeys[plan.id],
                            child: BundleCard(
                              plan: plan,
                              isSelected: selectedPlan.id == plan.id,
                              onSelect: () => _controller.selectPlan(plan),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Feature Comparison Matrix
                        _buildFeatureComparisonMatrix(),
                        const SizedBox(height: 24),

                        // FAQ Accordion Section
                        _buildFaqSection(),
                        const SizedBox(height: 24),

                        // Security & Standard Trust Badge
                        _buildTrustBadge(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Sticky Bottom CTA Bar
            _buildBottomBar(selectedPlan),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.headerDarkGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go(RouteNames.dashboard);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Paket Langganan SPPG',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Program MBG BGN 2024 • Kemenkes RI',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 14),
                const SizedBox(width: 4),
                Text(
                  'RESMI',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.accentGold,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3628),
            Color(0xFF1B4E41),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F3628),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UPGRADE SPPG LISENSI',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.accentGold,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accentGold,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tingkatkan Kapasitas Audit Gizi Unit SPPG Anda',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buka akses tak terbatas kuota AI scan ompreng, verifikasi AKG multi-demografis sekolah, dan ekspor laporan rekapitulasi audit otomatis.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionBanner() {
    final activePlan = UserSessionService.instance.account.subscriptionPlan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBCE3C6)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF1E6C45),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Paket aktif Anda saat ini: $activePlan',
              style: AppTypography.titleSmall.copyWith(
                color: const Color(0xFF1E6C45),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _controller.plans.asMap().entries.map((entry) {
          final idx = entry.key;
          final plan = entry.value;
          final isSelected = _controller.selectedPlan.id == plan.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    plan.icon,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.primaryDeep,
                  ),
                  const SizedBox(width: 6),
                  Text(plan.name),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => _selectAndScrollToPlan(idx),
              selectedColor: AppColors.primaryForest,
              backgroundColor: Colors.white,
              labelStyle: AppTypography.titleSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primaryForest : const Color(0xFFD6DFD5),
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureComparisonMatrix() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2ECE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart_rounded, color: AppColors.primaryDeep, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Perbandingan Fitur Paket',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2ECE0)),
          const SizedBox(height: 10),
          _buildMatrixHeader(),
          const Divider(height: 1, color: Color(0xFFE2ECE0)),
          const SizedBox(height: 6),
          _buildMatrixRow('AI Scan Ompreng', 'Tak Terbatas', 'Tak Terbatas', 'Tak Terbatas'),
          _buildMatrixRow('Akurasi Kalori 5 Pilar', '✓', '✓', '✓'),
          _buildMatrixRow('Format Ekspor', 'PDF Standar', 'XLSX & PDF', 'XLSX & PDF API'),
          _buildMatrixRow('Demografi Sasaran', 'Umum', 'SD-SMA Lengkap', 'Multi-Sentral'),
          _buildMatrixRow('Masa Simpan Audit', '30 Hari', '1 Tahun', 'Tak Terbatas'),
          _buildMatrixRow('Notifikasi Defisit >15%', 'Manual', 'Otomatis Push', 'Realtime Prioritas'),
        ],
      ),
    );
  }

  Widget _buildMatrixHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Fitur',
              style: AppTypography.captionBold.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Mandiri',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Pro',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(
                color: const Color(0xFF1E6C45),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Sentral',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(
                color: const Color(0xFF102A4A),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String feature, String starter, String pro, String enterprise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              starter,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6ED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pro,
                textAlign: TextAlign.center,
                style: AppTypography.captionBold.copyWith(
                  color: const Color(0xFF1E6C45),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              enterprise,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2ECE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, color: AppColors.primaryDeep, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pertanyaan Umum (FAQ)',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...PricingController.faqs.map(
            (faq) => Theme(
              data: ThemeData(dividerColor: Colors.transparent),
              child: Material(
                type: MaterialType.transparency,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  title: Text(
                    faq['question']!,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  children: [
                    Text(
                      faq['answer']!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4D5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: Color(0xFF1E6C45), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enkripsi SSL 256-bit & Midtrans Sandbox',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Simulasi pembayaran aman terproteksi. Data audit SPPG tersimpan sesuai standar kerahasiaan BGN.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PricingPlanModel selectedPlan) {
    final formattedPrice = MidtransSandboxService.formatRupiah(selectedPlan.billedPrice);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: const Color(0xFFE6EBE2)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedPlan.name,
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          formattedPrice,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryForest,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/${selectedPlan.billingPeriod.startsWith('per 3') ? '3 bln' : selectedPlan.billingPeriod.contains('bulan') ? 'bln' : 'thn'}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _handleProceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lanjutkan',
                    style: AppTypography.button.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
