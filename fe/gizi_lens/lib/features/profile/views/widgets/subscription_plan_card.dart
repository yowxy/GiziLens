import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

/// Subscription card showing the active plan, monthly scan quota, and the
/// upgrade call-to-action.
class SubscriptionPlanCard extends StatelessWidget {
  final String planName;
  final bool isPremium;
  final int scansUsed;
  final int monthlyQuota;
  final VoidCallback onUpgradeTap;

  const SubscriptionPlanCard({
    super.key,
    this.planName = AppStrings.planFreeName,
    this.isPremium = false,
    required this.scansUsed,
    required this.monthlyQuota,
    required this.onUpgradeTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeQuota = monthlyQuota > 0 ? monthlyQuota : 1;
    final used = scansUsed.clamp(0, safeQuota).toInt();
    final remaining = safeQuota - used;
    final progress = isPremium ? 1.0 : used / safeQuota;
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F261E),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.planIconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 25,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.planActiveLabel,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPremium
                      ? const Color(0xFFFEF3E2)
                      : AppColors.planFreePillBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isPremium
                        ? const Color(0xFFF3C97A)
                        : AppColors.planFreePillBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  isPremium ? 'PREMIUM' : AppStrings.planBadgeFree,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: isPremium
                        ? const Color(0xFF9E5C14)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.profileDivider,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.planQuotaTitle,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isPremium
                    ? 'Unlimited ($scansUsed scan bulan ini)'
                    : AppStrings.planQuotaUsage(scansUsed, monthlyQuota),
                style: AppTypography.titleSmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPremium
                      ? 'Kuota tak terbatas aktif'
                      : AppStrings.planQuotaPercent(percent),
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.planRemainingBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isPremium
                      ? 'Unlimited'
                      : AppStrings.planQuotaRemaining(remaining),
                  style: AppTypography.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.planRemainingText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.progressTrack),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDeep,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.sync_rounded,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                AppStrings.planRenewNote,
                style: AppTypography.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUpgradeButton(),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onUpgradeTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 15,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                isPremium
                    ? 'Kelola Paket Langganan'
                    : AppStrings.btnUpgradePremium,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
