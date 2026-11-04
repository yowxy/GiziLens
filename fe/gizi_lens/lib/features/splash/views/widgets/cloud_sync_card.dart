import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/badge_chip.dart';

class CloudSyncCard extends StatelessWidget {
  final double progress;
  final bool isConnected;

  const CloudSyncCard({
    super.key,
    required this.progress,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _SpinningSyncIcon(progress: progress, isConnected: isConnected),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.cloudConnecting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BadgeChip(
                label: AppStrings.cloudVersion,
                backgroundColor: AppColors.badgeOnlineBg,
                textColor: AppColors.badgeOnlineText,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: AppTypography.badge.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.badgeOnlineText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.progressTrack,
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.linear,
                        width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
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

class _SpinningSyncIcon extends StatelessWidget {
  final double progress;
  final bool isConnected;

  const _SpinningSyncIcon({
    required this.progress,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: isConnected ? 0 : progress * 4 * math.pi,
      child: const Icon(
        Icons.sync_rounded,
        size: 18,
        color: AppColors.primaryDark,
      ),
    );
  }
}
