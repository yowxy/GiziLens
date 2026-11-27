import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

/// Top header for Dashboard featuring deep forest green theme, officer identity, and notification bell.
class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String officerName;
  final String unitName;
  final bool hasNotification;
  final String? premiumPlanName;
  final VoidCallback onNotificationTap;

  const DashboardHeader({
    super.key,
    this.greeting = AppStrings.greetingMorning,
    this.officerName = AppStrings.dashboardOfficerName,
    this.unitName = AppStrings.dashboardOfficerUnit,
    this.hasNotification = true,
    this.premiumPlanName,
    required this.onNotificationTap,
  });

  bool get _isPremium =>
      premiumPlanName != null && premiumPlanName!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      color: AppColors.headerDarkGreen,
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: AppTypography.h1.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.25,
                  ),
                ),
                Text(
                  officerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F6EF),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accentCheckGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              unitName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.badge.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD6943C),
                              Color(0xFFE6B45A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x28000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 14,
                              color: Color(0xFF231602),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              premiumPlanName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFF231602),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onNotificationTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  if (hasNotification)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.notificationDot,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.headerDarkGreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
