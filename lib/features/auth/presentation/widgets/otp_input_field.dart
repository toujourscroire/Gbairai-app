import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/design_tokens.dart';

class OtpInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: GDuration.fast,
      width: 44,
      height: 54,
      decoration: BoxDecoration(
        color: GColors.surface,
        borderRadius: BorderRadius.circular(GRadius.md),
        border: Border.all(
          color: hasError
              ? GColors.error
              : focusNode.hasFocus
                  ? GColors.orange
                  : GColors.border,
          width: focusNode.hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GTextStyle.headlineMedium.copyWith(
          color: hasError ? GColors.error : GColors.textPrimary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          // Gérer le backspace
          if (value.isEmpty) {
            onChanged('');
          } else {
            onChanged(value.substring(value.length - 1));
          }
        },
      ),
    );
  }
}
