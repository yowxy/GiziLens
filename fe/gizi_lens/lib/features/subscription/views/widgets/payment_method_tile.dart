import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../models/payment_order_model.dart';

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethodOption method;
  final bool isSelected;
  final VoidCallback onSelect;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onSelect,
  });

  IconData _getIcon() {
    switch (method.type) {
      case PaymentMethodType.qris:
        return Icons.qr_code_2_rounded;
      case PaymentMethodType.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethodType.creditCard:
        return Icons.credit_card_rounded;
    }
  }

  Color _getBadgeColor() {
    switch (method.type) {
      case PaymentMethodType.qris:
        return const Color(0xFFE53935);
      case PaymentMethodType.bankTransfer:
        return const Color(0xFF0F3628);
      case PaymentMethodType.creditCard:
        return const Color(0xFF102A4A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primaryForest : AppColors.borderLight,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppColors.primaryForest.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          else
            const BoxShadow(
              color: Color(0x06000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon / Brand Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getBadgeColor().withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getBadgeColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Method Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              method.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (method.fee == 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F6ED),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Gratis Admin',
                                style: AppTypography.captionBold.copyWith(
                                  color: const Color(0xFF1E6C45),
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        method.subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Radio Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryForest
                          : const Color(0xFFB0BEB6),
                      width: isSelected ? 6.5 : 1.8,
                    ),
                    color: Colors.white,
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
