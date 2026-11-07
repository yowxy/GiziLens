import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';

class ScanValidationCard extends StatelessWidget {
  final bool isLightingOk;
  final bool isWholeTrayVisible;
  final bool isCameraFocused;
  final bool isWithinFrame;

  const ScanValidationCard({
    super.key,
    this.isLightingOk = false,
    this.isWholeTrayVisible = false,
    this.isCameraFocused = false,
    this.isWithinFrame = false,
  });

  int get fulfilledCount {
    var count = 0;
    if (isLightingOk) count++;
    if (isWholeTrayVisible) count++;
    if (isCameraFocused) count++;
    if (isWithinFrame) count++;
    return count;
  }

  bool get isAllFulfilled => fulfilledCount == 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isAllFulfilled
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.ensurePhotoReady,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAllFulfilled
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$fulfilledCount/4 Terpenuhi',
                  style: AppTypography.captionBold.copyWith(
                    color: isAllFulfilled
                        ? const Color(0xFF15803D)
                        : const Color(0xFFDC2626),
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCheckItem(
                  label: AppStrings.reqLighting,
                  isOk: isLightingOk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCheckItem(
                  label: AppStrings.reqWholeTray,
                  isOk: isWholeTrayVisible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCheckItem(
                  label: AppStrings.reqCameraFocus,
                  isOk: isCameraFocused,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCheckItem(
                  label: AppStrings.reqInFrame,
                  isOk: isWithinFrame,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isAllFulfilled
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAllFulfilled
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFFECACA),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAllFulfilled
                      ? Icons.check_circle_rounded
                      : Icons.cancel_outlined,
                  size: 22,
                  color: isAllFulfilled
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAllFulfilled
                            ? AppStrings.photoReadyTitle
                            : AppStrings.photoNotReadyTitle,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isAllFulfilled
                              ? const Color(0xFF15803D)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAllFulfilled
                            ? AppStrings.photoReadySubtitle
                            : AppStrings.photoNotReadySubtitle,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          color: isAllFulfilled
                              ? const Color(0xFF166534)
                              : const Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool isOk,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            size: 16,
            color: isOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionBold.copyWith(
                fontSize: 11,
                color: isOk ? const Color(0xFF15803D) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
