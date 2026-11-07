import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

/// Responsive 6-digit OTP code input widget with auto-advance, backspace handling,
/// and paste support.
class OtpCodeInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  const OtpCodeInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _getCombinedOtp() {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste of multiple characters
      final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty) {
        for (int i = 0; i < widget.length; i++) {
          if (i < clean.length) {
            _controllers[i].text = clean[i];
          }
        }
        final targetIndex = (clean.length < widget.length) ? clean.length : widget.length - 1;
        _focusNodes[targetIndex].requestFocus();
      }
    } else if (value.isNotEmpty) {
      // Single digit entered -> advance to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final otp = _getCombinedOtp();
    widget.onChanged(otp);
    if (otp.length == widget.length) {
      widget.onCompleted?.call(otp);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive box size
        final totalSpacing = (widget.length - 1) * 8.0;
        final availableWidth = constraints.maxWidth - totalSpacing;
        final boxSize = (availableWidth / widget.length).clamp(38.0, 52.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            final controller = _controllers[index];
            final focusNode = _focusNodes[index];
            final isFocused = focusNode.hasFocus;
            final hasValue = controller.text.isNotEmpty;

            return SizedBox(
              width: boxSize,
              height: boxSize * 1.15,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      controller.text.isEmpty &&
                      index > 0) {
                    _controllers[index - 1].clear();
                    _focusNodes[index - 1].requestFocus();
                    widget.onChanged(_getCombinedOtp());
                    setState(() {});
                  }
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: AppTypography.h2.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    hintText: '-',
                    hintStyle: AppTypography.titleLarge.copyWith(
                      color: AppColors.borderMedium,
                      fontSize: 18,
                    ),
                    filled: true,
                    fillColor: (isFocused || hasValue)
                        ? Colors.white
                        : const Color(0xFFF7F8F5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: hasValue
                            ? AppColors.primaryDeep
                            : AppColors.borderLight,
                        width: hasValue ? 1.4 : 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primaryDeep,
                        width: 1.8,
                      ),
                    ),
                  ),
                  onChanged: (val) => _onDigitChanged(index, val),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
