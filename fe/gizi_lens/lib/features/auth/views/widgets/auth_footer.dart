import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/status_dot.dart';

/// Reusable footer displaying policy links, terms, and GiziLens system version.
class AuthFooter extends StatelessWidget {
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onTermsTap;

  const AuthFooter({
    super.key,
    this.onPrivacyTap,
    this.onTermsTap,
  });

  void _showModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surface,
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
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: onPrivacyTap ??
                  () => _showModal(
                        context,
                        AppStrings.privacyPolicy,
                        'Kebijakan privasi sistem audit MBG melindungi seluruh data identitas petugas dan metadata citra baki saji sesuai UU PDP.',
                      ),
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.privacyPolicy,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A5852),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF8FA196),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '•',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
            GestureDetector(
              onTap: onTermsTap ??
                  () => _showModal(
                        context,
                        AppStrings.termsOfServiceMBG,
                        'Ketentuan layanan operasional SPPG mengatur tata cara verifikasi porsi dan kalibrasi standar mutu makanan bergizi gratis.',
                      ),
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppStrings.termsOfServiceMBG,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A5852),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFF8FA196),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }
}
