import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/otp_controller.dart';
import 'widgets/auth_footer.dart';
import 'widgets/otp_code_input.dart';
import 'widgets/otp_verification_dialog.dart';

/// OTP verification screen for confirming email or phone token.
class OtpVerificationScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPhone;
  final bool isForgotPassword;

  const OtpVerificationScreen({
    super.key,
    this.initialEmail,
    this.initialPhone,
    this.isForgotPassword = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late final OtpController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OtpController(
      email: widget.initialEmail ?? '-',
      phone: widget.initialPhone ?? '-',
      onAutoVerified: _handleAutoVerified,
    );
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

  void _handleAutoVerified() {
    if (!mounted) return;
    _showVerificationSuccessDialog();
  }

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();

    final success = await _controller.verifyOtp();
    if (success && mounted) {
      _showVerificationSuccessDialog();
    }
  }

  Future<void> _showVerificationSuccessDialog() async {
    await OtpVerificationDialog.show(
      context,
      onNext: () {
        if (widget.isForgotPassword) {
          context.go(RouteNames.login);
          return;
        }
        context.go(RouteNames.completeProfile);
      },
    );
  }

  Future<void> _handleResend() async {
    final success = await _controller.resendOtp();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kode OTP acak baru (${_controller.generatedOtp}) telah dibuat & tautan verifikasi dikirimkan ke ${_controller.email}.',
            style: AppTypography.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDeep,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (!success && _controller.errorMessage != null && mounted) {
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

  void _showSmsHelpDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.sms_outlined, color: AppColors.primaryDeep),
                  const SizedBox(width: 8),
                  Text(
                    'Bantuan Pengiriman SMS OTP',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Pastikan pulsa reguler Anda mencukupi untuk menerima SMS dari gateway BGN. Jika SMS belum masuk dalam 2 menit, periksa folder spam atau minta bantuan supervisor SPPG Anda.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Tutup',
                    style: AppTypography.button.copyWith(fontSize: 14),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenHorizontalPadding,
              vertical: 14,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(RouteNames.login);
                            }
                          },
                        ),
                        Image.asset(
                          AppAssets.logoGiziLens,
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.portalBadgeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFCEE0D0),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: AppColors.portalBadgeText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.otpBadge,
                            style: AppTypography.badge.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.portalBadgeText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppStrings.otpTitle,
                      style: AppTypography.h1.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.otpSubtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.borderLight,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: Stack(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE4F3E8),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.mail_outline_rounded,
                                      color: Color(0xFF1B493B),
                                      size: 22,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.all(1.5),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      size: 14,
                                      color: AppColors.accentCheckGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.otpSentToPrefix,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _controller.maskedEmail,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _controller.maskedPhone,
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(RouteNames.login);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 14,
                                    color: AppColors.accentAmber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.btnUbah,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentAmber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Official Generated OTP Card
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 18, bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF0FDF4),
                            Color(0xFFE8F7ED),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFB9E3C6),
                          width: 1.3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0C166534),
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
                              Image.asset(
                                AppAssets.logoGiziLens,
                                height: 22,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'KODE OTP RESMI GIZILENS',
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                    color: const Color(0xFF144638),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentCheckGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Aktif',
                                      style: AppTypography.badge.copyWith(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kode Keamanan 6 Digit (Acak):',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _controller.generatedOtp,
                                      style: AppTypography.h1.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3.5,
                                        color: const Color(0xFF144638),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _controller.autoFillOtp();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDeep,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                icon: const Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: Color(0xFFFDE047),
                                ),
                                label: const Text(
                                  'Isi Otomatis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Kode baru otomatis di-generate secara acak setiap Anda menekan Kirim Ulang. Atau klik tautan verifikasi pada email Anda.',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 11,
                                    color: const Color(0xFF15803D),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Text(
                        AppStrings.enterOtpLabel,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    OtpCodeInput(
                      length: 6,
                      code: _controller.currentOtp,
                      onChanged: _controller.updateOtp,
                      onCompleted: (_) => _handleVerifyOtp(),
                    ),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _controller.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        AppStrings.haventReceivedCode,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: AppColors.accentAmber,
                        ),
                        const SizedBox(width: 4),
                        if (_controller.canResend)
                          GestureDetector(
                            onTap: _handleResend,
                            child: Text(
                              AppStrings.resendCodeAction,
                              style: AppTypography.titleSmall.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentAmber,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${AppStrings.resendCodeTimerPrefix} (${_controller.secondsRemaining}s)',
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentAmber,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showSmsHelpDialog,
                          child: Text(
                            AppStrings.smsHelp,
                            style: AppTypography.titleSmall.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      text: AppStrings.btnVerifikasi,
                      backgroundColor: _controller.isOtpComplete
                          ? AppColors.primaryDeep
                          : AppColors.buttonAuth,
                      height: 52,
                      borderRadius: 14,
                      isLoading: _controller.isLoading,
                      leadingIcon: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      trailingIcon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _handleVerifyOtp,
                    ),
                    const SizedBox(height: 32),
                    const AuthFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
