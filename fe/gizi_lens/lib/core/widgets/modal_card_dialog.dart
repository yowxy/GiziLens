import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class ModalCardDialog extends StatelessWidget {
  final Widget? topBadge;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? customContent;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final IconData? primaryButtonIcon;
  final Color primaryButtonColor;
  final Color primaryButtonTextColor;
  final Color? primaryButtonIconColor;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final bool showCloseButton;
  final VoidCallback? onClosePressed;
  final Color backgroundColor;
  final double maxWidth;

  const ModalCardDialog({
    super.key,
    this.topBadge,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.customContent,
    required this.primaryButtonText,
    required this.onPrimaryPressed,
    this.primaryButtonIcon,
    this.primaryButtonColor = AppColors.primaryDeep,
    this.primaryButtonTextColor = Colors.white,
    this.primaryButtonIconColor,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.showCloseButton = false,
    this.onClosePressed,
    this.backgroundColor = Colors.white,
    this.maxWidth = 360,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'ModalCardDialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => builder(ctx),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: 0.88 + (0.12 * curvedValue),
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E9E2),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F261E),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (topBadge != null) ...[
                        topBadge!,
                        const SizedBox(height: 18),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.h2.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (subtitleWidget != null)
                        subtitleWidget!
                      else if (subtitle != null)
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.48,
                          ),
                        ),
                      if (customContent != null) ...[
                        const SizedBox(height: 16),
                        customContent!,
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: onPrimaryPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryButtonColor,
                            foregroundColor: primaryButtonTextColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (primaryButtonIcon != null) ...[
                                Icon(
                                  primaryButtonIcon,
                                  size: 20,
                                  color: primaryButtonIconColor ?? primaryButtonTextColor,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  primaryButtonText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: primaryButtonTextColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (secondaryButtonText != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: onSecondaryPressed,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              side: const BorderSide(
                                color: Color(0xFFCFD8D0),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            child: Text(
                              secondaryButtonText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showCloseButton)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onClosePressed ?? () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
