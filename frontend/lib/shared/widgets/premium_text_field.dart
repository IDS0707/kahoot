import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_durations.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Premium glassy text input with focus glow + animated border.
class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onSubmitted,
    this.maxLength,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus != _focused) {
        setState(() => _focused = _focus.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primaryGlow.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        style: AppTypography.bodyLg(weight: FontWeight.w700),
        cursorColor: AppColors.accent,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        maxLength: widget.maxLength,
        validator: widget.validator,
        onFieldSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hint,
          counterText: '',
          prefixIcon: widget.prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 14, right: 8),
                  child: Icon(
                    widget.prefixIcon,
                    color: _focused ? AppColors.accent : AppColors.primaryGlow,
                    size: 22,
                  ),
                )
              : null,
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.prefixIcon != null ? 6 : AppSpacing.lg,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
