import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_checkbox.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../controllers/register_controller.dart';
import 'widgets/auth_footer.dart';

/// Registration screen for new MBG officers and nutrition personnel.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterController();
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

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    final result = await _controller.register();
    if (result != null && mounted) {
      context.push(
        RouteNames.otpVerification,
        extra: {
          'email': result.email,
          'phone': result.phone,
          'fullName': result.fullName,
        },
      );
    } else if (result == null && _controller.errorMessage != null && mounted) {
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

  void _showTermsDialog() {
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
              Text(
                'Syarat dan Ketentuan Registrasi MBG',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Dengan mendaftar sebagai auditor atau pelaksana SPPG, Anda setuju untuk menjaga kerahasiaan data standar nutrisi dan menjalankan verifikasi porsi sesuai petunjuk teknis Badan Gizi Nasional (BGN).',
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
                    'Saya Mengerti',
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
              vertical: 12,
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
                            Icons.verified_user_outlined,
                            size: 14,
                            color: AppColors.portalBadgeText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.registerBadge,
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
                      AppStrings.registerTitle,
                      style: AppTypography.h1.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.registerSubtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
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
                            CustomTextField(
                              label: AppStrings.fullNameFieldLabel,
                              isRequired: true,
                              hintText: AppStrings.fullNameFieldHint,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                                color: AppColors.iconFieldMuted,
                              ),
                              controller: _controller.fullNameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              validator: _controller.validateFullName,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: AppStrings.emailActiveLabel,
                              isRequired: true,
                              hintText: AppStrings.emailActiveHint,
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                size: 20,
                                color: AppColors.iconFieldMuted,
                              ),
                              controller: _controller.emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: _controller.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: AppStrings.phoneNumberLabel,
                              isRequired: true,
                              hintText: AppStrings.phoneNumberHint,
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 20,
                                color: AppColors.iconFieldMuted,
                              ),
                              controller: _controller.phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: _controller.validatePhone,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: AppStrings.registerPasswordLabel,
                              isRequired: true,
                              hintText: AppStrings.registerPasswordHint,
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
                              textInputAction: TextInputAction.next,
                              validator: _controller.validatePassword,
                              helperWidget: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppStrings.registerPasswordHelper,
                                      style: AppTypography.caption.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: AppStrings.confirmPasswordLabel,
                              isRequired: true,
                              hintText: AppStrings.confirmPasswordHint,
                              obscureText: !_controller.isConfirmPasswordVisible,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: AppColors.iconFieldMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _controller.isConfirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: AppColors.iconFieldMuted,
                                ),
                                onPressed: _controller.toggleConfirmPasswordVisibility,
                              ),
                              controller: _controller.confirmPasswordController,
                              textInputAction: TextInputAction.done,
                              validator: _controller.validateConfirmPassword,
                              onFieldSubmitted: (_) => _handleRegister(),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomCheckbox(
                                  value: _controller.agreeTerms,
                                  onChanged: _controller.setAgreeTerms,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _controller.setAgreeTerms(!_controller.agreeTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 12,
                                          height: 1.45,
                                          color: AppColors.textSecondary,
                                        ),
                                        children: [
                                          const TextSpan(text: AppStrings.agreeTermsPrefix),
                                          WidgetSpan(
                                            alignment: PlaceholderAlignment.baseline,
                                            baseline: TextBaseline.alphabetic,
                                            child: GestureDetector(
                                              onTap: _showTermsDialog,
                                              child: Text(
                                                AppStrings.agreeTermsLink,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const TextSpan(text: AppStrings.agreeTermsAnd),
                                          WidgetSpan(
                                            alignment: PlaceholderAlignment.baseline,
                                            baseline: TextBaseline.alphabetic,
                                            child: GestureDetector(
                                              onTap: _showTermsDialog,
                                              child: Text(
                                                AppStrings.agreePrivacyLink,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_controller.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _controller.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            AppButton(
                              text: AppStrings.btnDaftarAkun,
                              backgroundColor: _controller.isFormFilled
                                  ? AppColors.primaryDeep
                                  : AppColors.buttonAuth,
                              height: 52,
                              borderRadius: 14,
                              isLoading: _controller.isLoading,
                              trailingIcon: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: _handleRegister,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
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
