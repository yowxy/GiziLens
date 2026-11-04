import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_checkbox.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../controllers/login_controller.dart';
import 'widgets/auth_footer.dart';
import 'widgets/managed_access_notice.dart';
import 'widgets/official_portal_badge.dart';

/// Pixel-perfect implementation of Login Screen (1auth.png).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
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

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final success = await _controller.login();
    if (success && mounted) {
      context.go(RouteNames.completeProfile);
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.accentAmber),
            const SizedBox(width: 8),
            Text(
              'Reset Kata Sandi',
              style: AppTypography.titleLarge.copyWith(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Akun auditor SPPG terintegrasi dengan Pusat BGN. Silakan hubungi Administrator SPPG Wilayah Anda untuk mengatur ulang kredensial.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Mengerti',
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              vertical: 16,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // Logo GiziLens
              Image.asset(
                AppAssets.logoGiziLens,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              // Portal Resmi Auditor Pill
              const OfficialPortalBadge(),
              const SizedBox(height: 18),
              // Title
              Text(
                AppStrings.loginTitle,
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  AppStrings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Main Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Email atau ID Petugas
                      CustomTextField(
                        label: AppStrings.emailOrOfficerIdLabel,
                        headerTrailing: Text(
                          AppStrings.sppgResmiBadge,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                        hintText: AppStrings.emailOrOfficerIdHint,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: AppColors.iconFieldMuted,
                        ),
                        controller: _controller.emailOrIdController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _controller.validateEmailOrId,
                      ),
                      const SizedBox(height: 16),
                      // Field 2: Kata Sandi
                      CustomTextField(
                        label: AppStrings.passwordLabel,
                        hintText: AppStrings.passwordHint,
                        obscureText: !_controller.isPasswordVisible,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: AppColors.iconFieldMuted,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _controller.isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.iconFieldMuted,
                          ),
                          onPressed: _controller.togglePasswordVisibility,
                        ),
                        controller: _controller.passwordController,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: _controller.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      // Remember Me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomCheckbox(
                                value: _controller.rememberMe,
                                onChanged: _controller.setRememberMe,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _controller.setRememberMe(
                                  !_controller.rememberMe,
                                ),
                                child: Text(
                                  AppStrings.rememberMe,
                                  style: AppTypography.titleSmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showForgotPasswordDialog,
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              AppStrings.forgotPassword,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.accentAmber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Submit Button (Masuk ->)
                      AppButton(
                        text: AppStrings.btnMasuk,
                        backgroundColor: AppColors.buttonAuth,
                        height: 52,
                        borderRadius: 14,
                        isLoading: _controller.isLoading,
                        trailingIcon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Managed Access Card
              const ManagedAccessNotice(),
              const SizedBox(height: 28),
              // Footer
              const AuthFooter(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}
