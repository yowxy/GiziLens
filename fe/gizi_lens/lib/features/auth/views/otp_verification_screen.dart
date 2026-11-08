import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final String? fullName;
  final bool isForgotPassword;

  const OtpVerificationScreen({
    super.key,
    this.initialEmail,
    this.initialPhone,
    this.fullName,
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
      email: widget.initialEmail ?? AppStrings.defaultOtpEmail,
      phone: widget.initialPhone ?? AppStrings.defaultOtpPhone,
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

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();

    final success = await _controller.verifyOtp();
    if (success && mounted) {
      await OtpVerificationDialog.show(
        context,
        onNext: () {
          context.go(
            RouteNames.registerSuccess,
            extra: {
              'email': _controller.email,
              'fullName': widget.fullName ?? 'Nurul Gizi',
              'role': 'Ahli Gizi Lapangan',
              'unit': 'SPPG Cibinong Sentral 02',
            },
          );
        },
      );
    }
  }

  Future<void> _handleResend() async {
    final success = await _controller.resendOtp();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email verifikasi resmi dari Firebase telah dikirimkan ke ${_controller.email}. Silakan periksa inbox / spam email Anda.',
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
                    const SizedBox(height: 32),
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
