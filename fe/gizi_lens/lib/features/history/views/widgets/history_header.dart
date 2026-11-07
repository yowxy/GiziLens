import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

class HistoryHeader extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onNotificationTap;
  final bool hasNotification;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;

  const HistoryHeader({
    super.key,
    required this.onBackTap,
    required this.onNotificationTap,
    required this.hasNotification,
    required this.searchController,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      color: AppColors.headerDarkGreen,
      padding: EdgeInsets.fromLTRB(20, topPadding + 6, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onBackTap,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              InkWell(
                onTap: onNotificationTap,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(6),
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
          const SizedBox(height: 12),

          // Monitoring Gizi MBG Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0x28FFFFFF),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: Color(0xFFBFE0D4),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.monitoringGiziMbgBadge,
                  style: AppTypography.badge.copyWith(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            AppStrings.historyTitle,
            style: AppTypography.h1.copyWith(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            AppStrings.historySubtitle,
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFFA5BFB6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13.5,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.searchHistoryHint,
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF233B32),
                  size: 22,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                          size: 18,
                        ),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
