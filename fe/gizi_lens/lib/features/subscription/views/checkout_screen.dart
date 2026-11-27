import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/route_names.dart';
import '../controllers/checkout_controller.dart';
import '../models/payment_order_model.dart';
import '../models/pricing_plan_model.dart';
import '../services/midtrans_sandbox_service.dart';
import 'widgets/payment_method_tile.dart';
import 'widgets/payment_success_dialog.dart';
import 'widgets/qris_matrix_widget.dart';

class CheckoutScreen extends StatefulWidget {
  final PricingPlanModel plan;

  const CheckoutScreen({
    super.key,
    required this.plan,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with WidgetsBindingObserver {
  late final CheckoutController _controller;
  Timer? _countdownTimer;
  int _remainingSeconds = 15 * 60; // 15-minute Midtrans Snap payment window
  bool _awaitingSnapReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = CheckoutController(plan: widget.plan);
    _controller.addListener(_onControllerUpdate);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _awaitingSnapReturn &&
        !_controller.isSuccess &&
        !_controller.isProcessingPayment) {
      _awaitingSnapReturn = false;
      _verifyMidtransPayment();
    }
  }

  String get _formattedCountdown {
    final mins = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handlePayNow() async {
    final order = _controller.currentOrder;
    if (order == null) return;

    if (order.isLiveSandboxApi &&
        order.redirectUrl != null &&
        order.redirectUrl!.isNotEmpty) {
      final uri = Uri.tryParse(order.redirectUrl!);
      if (uri != null) {
        _awaitingSnapReturn = true;
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        if (launched) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Selesaikan pembayaran di Midtrans Snap, lalu kembali ke aplikasi untuk verifikasi otomatis.',
              ),
              backgroundColor: AppColors.primaryForest,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        _awaitingSnapReturn = false;
      }
    }

    final success = await _controller.processPayment();
    if (!mounted) return;

    if (success && _controller.currentOrder != null) {
      await PaymentSuccessDialog.show(context, _controller.currentOrder!);
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: AppColors.statTidakSesuaiRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _verifyMidtransPayment() async {
    final status = await _controller.verifyLiveMidtransPayment();
    if (!mounted) return;

    if (status == PaymentStatus.settlement && _controller.currentOrder != null) {
      await PaymentSuccessDialog.show(context, _controller.currentOrder!);
      return;
    }

    final msg = _controller.errorMessage ??
        'Status Midtrans masih menunggu pembayaran (${status.name}).';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: status == PaymentStatus.pending
            ? const Color(0xFFC98235)
            : AppColors.statTidakSesuaiRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label berhasil disalin ke clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF1E6C45),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _controller.currentOrder;
    final isLoading = _controller.isLoading;
    final isProcessing = _controller.isProcessingPayment;

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
            // Header App Bar
            _buildAppBar(context),

            // Scrollable Content
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryForest,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Midtrans Sandbox Environment Banner
                              _buildSandboxBanner(order),
                              const SizedBox(height: 20),

                              // Order Summary Card
                              if (order != null) _buildOrderSummaryCard(order),
                              const SizedBox(height: 20),

                              // Payment Method Selection
                              _buildPaymentMethodSection(),
                              const SizedBox(height: 20),

                              // Dynamic Method Instruction Box (QRIS / VA / Card)
                              if (order != null) _buildDynamicPaymentInstruction(order),
                              const SizedBox(height: 24),

                              // Security Guarantee Note
                              _buildSecurityNote(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            // Bottom Payment Action Bar
            if (order != null) _buildBottomBar(order, isProcessing),
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
                context.go(RouteNames.pricing);
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
                  'Pembayaran Paket SPPG',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Midtrans Payment Gateway (Sandbox)',
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _formattedCountdown,
                  style: AppTypography.captionBold.copyWith(
                    color: Colors.white,
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

  Widget _buildSandboxBanner(PaymentOrderModel? order) {
    final isLiveApi = order?.isLiveSandboxApi ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF7D9A4), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC98235).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science_rounded, color: Color(0xFFC98235), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'MODE MIDTRANS SANDBOX',
                      style: AppTypography.captionBold.copyWith(
                        color: const Color(0xFF9E5C14),
                        fontSize: 11,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLiveApi ? const Color(0xFF1E6C45) : const Color(0xFFC98235),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isLiveApi ? 'SNAP API' : 'SIMULASI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isLiveApi
                      ? 'Terhubung langsung ke Midtrans Sandbox Snap API (gratis/uji coba). Selesaikan pembayaran tes tanpa memotong saldo riil.'
                      : 'Integrasi ini berjalan pada Midtrans Sandbox. Anda dapat menguji transaksi pembayaran dengan simulasi settlement resmi tanpa memotong saldo riil.',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF7C531E),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(PaymentOrderModel order) {
    final hasUnit = order.sppgUnit != null && order.sppgUnit!.trim().isNotEmpty && order.sppgUnit != '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2ECE0)),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Ringkasan Tagihan',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.planName,
                  style: AppTypography.captionBold.copyWith(
                    color: const Color(0xFF1E6C45),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE6EBE2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ID: ${order.orderId}',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                      if (hasUnit) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Unit: ${order.sppgUnit}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(order.orderId, 'Order ID'),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: AppColors.primaryForest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2ECE0)),
          const SizedBox(height: 14),

          _buildSummaryRow(
            'Harga Paket (${widget.plan.billingPeriod})',
            MidtransSandboxService.formatRupiah(order.planPrice),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'PPN (11%)',
            MidtransSandboxService.formatRupiah(order.taxAmount),
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Biaya Transaksi / Admin',
            order.adminFee == 0
                ? 'Gratis (Rp 0)'
                : MidtransSandboxService.formatRupiah(order.adminFee),
            isHighlighted: order.adminFee == 0,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2ECE0)),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Pembayaran',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                MidtransSandboxService.formatRupiah(order.totalAmount),
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryForest,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: isHighlighted ? const Color(0xFF1E6C45) : AppColors.textPrimary,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih Metode Pembayaran',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Dukungan kanal pembayaran resmi Midtrans Snap Sandbox.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),

        ..._controller.availableMethods.map(
          (method) => PaymentMethodTile(
            method: method,
            isSelected: _controller.selectedMethod.id == method.id,
            onSelect: () => _controller.selectMethod(method),
          ),
        ),
      ],
    );
  }

  Widget _buildDynamicPaymentInstruction(PaymentOrderModel order) {
    switch (order.selectedMethod.type) {
      case PaymentMethodType.qris:
        return _buildQrisInstruction(order);
      case PaymentMethodType.bankTransfer:
        return _buildVaInstruction(order);
      case PaymentMethodType.creditCard:
        return _buildCreditCardInstruction(order);
    }
  }

  Widget _buildQrisInstruction(PaymentOrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2ECE0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_2_rounded, color: Color(0xFFE53935), size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'QRIS Dinamis Midtrans',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE4E1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NMID: ID102003948571',
                  style: AppTypography.captionBold.copyWith(
                    color: const Color(0xFFB3261E),
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QRIS Matrix Container
          QrisMatrixWidget(
            payload: order.qrPayload ?? order.orderId,
          ),
          const SizedBox(height: 14),

          Text(
            'Scan QR menggunakan aplikasi e-wallet atau m-Banking pilihan Anda.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'BCA Mobile • GoPay • ShopeePay • DANA • OVO • Livin Mandiri',
            style: AppTypography.captionBold.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVaInstruction(PaymentOrderModel order) {
    final va = order.vaNumber ?? '8801293847562819';
    final bankName = order.selectedMethod.name;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Nomor Virtual Account',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  bankName,
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.primaryForest,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // VA Number Copy Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD6DFD5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    va,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: AppColors.primaryDark,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(va, 'Nomor Virtual Account'),
                  icon: const Icon(Icons.copy_rounded, color: AppColors.primaryForest, size: 20),
                  tooltip: 'Salin Nomor VA',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Instructions Accordion
          Text(
            'Panduan Transfer:',
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _buildStepBullet('1', 'Buka aplikasi Mobile Banking atau ATM bank Anda.'),
          _buildStepBullet('2', 'Pilih menu Transfer > Virtual Account / Pembayaran.'),
          _buildStepBullet('3', 'Masukkan nomor Virtual Account di atas.'),
          _buildStepBullet('4', 'Pastikan nama penerima adalah "SPPG GiziLens - BGN".'),
          _buildStepBullet('5', 'Konfirmasi pembayaran. Status otomatis terupdate secara instan.'),
        ],
      ),
    );
  }

  Widget _buildCreditCardInstruction(PaymentOrderModel order) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kartu Tes Midtrans Sandbox',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Icon(Icons.credit_card_rounded, color: Color(0xFF102A4A), size: 22),
            ],
          ),
          const SizedBox(height: 14),

          // Test Card Mockup
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102A4A), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22102A4A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MIDTRANS SANDBOX CARD',
                      style: AppTypography.captionBold.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const Icon(Icons.contactless_rounded, color: Colors.white, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '4811  1111  1111  1114',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VALID THRU',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '12/28',
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CVV',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white60,
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '123',
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'VISA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Klik tombol bayar di bawah untuk mensimulasikan otentikasi 3D Secure dan settlement kartu secara otomatis.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBullet(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryForest.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: AppTypography.captionBold.copyWith(
                color: AppColors.primaryForest,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            'Enkripsi TLS 1.3 • Dilindungi Midtrans Payment Shield',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(PaymentOrderModel order, bool isProcessing) {
    final formattedTotal = MidtransSandboxService.formatRupiah(order.totalAmount);

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
                    'Total Tagihan',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedTotal,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryForest,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: isProcessing
                  ? null
                  : (order.isLiveSandboxApi && _awaitingSnapReturn
                        ? _verifyMidtransPayment
                        : _handlePayNow),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForest,
                disabledBackgroundColor: AppColors.primaryForest.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 18, color: AppColors.accentGold),
                        const SizedBox(width: 6),
                        Text(
                          order.isLiveSandboxApi
                              ? (_awaitingSnapReturn
                                    ? 'Verifikasi Midtrans'
                                    : 'Bayar via Midtrans')
                              : 'Bayar Sekarang',
                          style: AppTypography.button.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
