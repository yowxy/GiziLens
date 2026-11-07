import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/modal_card_dialog.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const LogoutConfirmationDialog({
    super.key,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onConfirmLogout,
  }) {
    return ModalCardDialog.show<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => LogoutConfirmationDialog(
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirmLogout?.call();
        },
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalCardDialog(
      backgroundColor: Colors.white,
      showCloseButton: true,
      onClosePressed: () => Navigator.of(context).pop(false),
      topBadge: _buildIconBadge(),
      title: AppStrings.logoutDialogTitle,
      subtitleWidget: _buildDescription(),
      primaryButtonText: AppStrings.logoutDialogConfirmBtn,
      primaryButtonColor: AppColors.dialogLogoutRed,
      primaryButtonTextColor: Colors.white,
      primaryButtonIcon: Icons.logout_rounded,
      onPrimaryPressed: onConfirm,
      secondaryButtonText: AppStrings.logoutDialogCancelBtn,
      onSecondaryPressed: onCancel,
    );
  }

  Widget _buildIconBadge() {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.dialogPeachBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.logout_rounded,
                size: 34,
                color: AppColors.dialogAmberIcon,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.dialogLockBadgeBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text.rich(
      TextSpan(
        style: AppTypography.bodyMedium.copyWith(
          color: const Color(0xFF475569),
          height: 1.52,
          fontSize: 13.5,
        ),
        children: [
          const TextSpan(text: AppStrings.logoutDialogBody1),
          TextSpan(
            text: AppStrings.logoutDialogBodyBold,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
