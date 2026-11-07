import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/modal_card_dialog.dart';

class ProfileUpdatedSuccessDialog extends StatelessWidget {
  final VoidCallback? onDismiss;

  const ProfileUpdatedSuccessDialog({
    super.key,
    this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onDismiss,
  }) {
    return ModalCardDialog.show<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProfileUpdatedSuccessDialog(
        onDismiss: () {
          Navigator.of(ctx).pop();
          onDismiss?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModalCardDialog(
      backgroundColor: const Color(0xFFFAF9F4),
      showCloseButton: false,
      topBadge: _buildIconBadge(),
      title: AppStrings.profileUpdatedSuccessTitle,
      subtitle: AppStrings.profileUpdatedSuccessSubtitle,
      primaryButtonText: AppStrings.profileUpdatedBackButton,
      primaryButtonColor: AppColors.primaryDeep,
      primaryButtonTextColor: Colors.white,
      primaryButtonIcon: Icons.arrow_forward_rounded,
      primaryButtonIconColor: AppColors.accentGold,
      onPrimaryPressed: onDismiss ?? () => Navigator.of(context).pop(),
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
              color: AppColors.dialogSageBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4E5DA),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 38,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 2,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.dialogAccentRing,
                  width: 2.4,
                ),
                color: const Color(0xFFFAF9F4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
