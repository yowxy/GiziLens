import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_dot.dart';

/// Screen displaying successful registration confirmation.
/// Automatically or manually redirects to Dashboard as requested.
class RegisterSuccessScreen extends StatefulWidget {
  final String? email;
  final String? fullName;
  final String? role;
  final String? unit;
  final bool autoRedirect;

  const RegisterSuccessScreen({
    super.key,
    this.email,
    this.fullName,
    this.role,
    this.unit,
    this.autoRedirect = true,
  });

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen> {
  Timer? _redirectTimer;
  int _countdown = 4;

  @override
  void initState() {
    super.initState();
    if (widget.autoRedirect) {
      _startAutoRedirect();
    }
  }

  void _startAutoRedirect() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        _redirectTimer?.cancel();
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    _redirectTimer?.cancel();
    if (mounted) {
      context.go(RouteNames.dashboard);
    }
  }

  void _navigateToLogin() {
    _redirectTimer?.cancel();
    if (mounted) {
      context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registeredEmail = widget.email ?? '-';
    final proposedRole = widget.role ?? AppStrings.defaultProposedRole;
    final assignedUnit = widget.unit ?? AppStrings.defaultAssignmentUnit;

    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenHorizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF1F6EE),
                            border: Border.all(
                              color: const Color(0xFFD6E7D6),
                              width: 2.0,
                            ),
                          ),
                        ),
                        Container(
                          width: 118,
                          height: 118,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0F0F261E),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.logoIcon,
                              width: 58,
                              height: 58,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 18,
                          left: 10,
                          child: Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFF144638),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 54,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE2A645),
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 2,
                          right: 34,
                          child: Text(
                            '<',
                            style: TextStyle(
                              color: Color(0xFFD6943C),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 48,
                          right: 6,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF7FAEA0),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          right: 22,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF43584E),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          left: 16,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFBFD2C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.registrationSuccessTitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.h1.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.registrationSuccessSubtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.mail_outline_rounded,
                          label: AppStrings.registeredAccountLabel,
                          value: registeredEmail,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFEDF1EA),
                          ),
                        ),
                        _buildInfoRow(
                          icon: Icons.badge_outlined,
                          label: AppStrings.proposedRoleLabel,
                          value: proposedRole,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFEDF1EA),
                          ),
                        ),
                        _buildInfoRow(
                          icon: Icons.apartment_outlined,
                          label: AppStrings.assignmentUnitLabel,
                          value: assignedUnit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (widget.autoRedirect)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryDeep,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${AppStrings.autoRedirectingDashboard} $_countdown detik...',
                            style: AppTypography.caption.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 36),
                  AppButton(
                    text: AppStrings.btnKembaliKeLogin,
                    backgroundColor: AppColors.primaryDeep,
                    height: 52,
                    borderRadius: 14,
                    leadingIcon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _navigateToLogin,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.dashboard_outlined,
                      size: 16,
                      color: AppColors.primaryDeep,
                    ),
                    label: Text(
                      AppStrings.btnMasukDashboard,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    onPressed: _navigateToDashboard,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const StatusDot(
                        color: AppColors.accentCheckGreen,
                        size: 6,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.appVersionString,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
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
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7F73),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.titleSmall.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
