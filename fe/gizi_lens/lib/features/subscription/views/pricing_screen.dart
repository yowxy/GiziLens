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

  @override
  void initState() {
    super.initState();
    _controller = PricingController();
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
                        const SizedBox(height: 20),

                        // Active plan banner if already subscribed
                        if (UserSessionService.instance.account.isPremium) ...[
                          _buildActiveSubscriptionBanner(),
                          const SizedBox(height: 16),
                        ],

                        // Single Premium Package Card
                        BundleCard(
                          plan: selectedPlan,
                          isSelected: true,
                          onSelect: () => _controller.selectPlan(selectedPlan),
                        ),
                        const SizedBox(height: 20),

                        // Free vs Premium Comparison Matrix
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
            'Buka 500 scan ompreng AI per bulan, verifikasi AKG multi-demografis sekolah, dan ekspor laporan rekapitulasi audit otomatis.',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                color: AppColors.accentGold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Rp299.000/bulan untuk 500 scan — sekitar Rp10.000 per hari kalender.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentGold,
                    fontSize: 11.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
                  'Perbandingan Free vs Premium',
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
          _buildMatrixRow('Kuota AI Scan Ompreng', '10 / bulan', '500 / bulan'),
          _buildMatrixRow('Analisis 5 Pilar AKG', '✓', '✓'),
          _buildMatrixRow('Ekspor Laporan PDF + SHA-256', 'Tidak tersedia', 'Lengkap & Resmi'),
          _buildMatrixRow('Demografi Sasaran AKG', 'Standar', 'SD – SMA Lengkap'),
          _buildMatrixRow('Riwayat & Audit Cloud', '30 Hari', '12 Bulan'),
          _buildMatrixRow('Peringatan Defisit >15%', 'Manual', 'Otomatis Prioritas'),
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
            flex: 4,
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
              'Gratis',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Premium',
              textAlign: TextAlign.center,
              style: AppTypography.captionBold.copyWith(
                color: const Color(0xFF1E6C45),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow(String feature, String freeTier, String premiumTier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
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
              freeTier,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6ED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                premiumTier,
                textAlign: TextAlign.center,
                style: AppTypography.captionBold.copyWith(
                  color: const Color(0xFF1E6C45),
                  fontSize: 11,
                ),
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
