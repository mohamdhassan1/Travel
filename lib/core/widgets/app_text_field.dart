import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Labeled text input with consistent styling and an optional
/// password-visibility toggle.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.isPassword = false,
    this.showPasswordLabel,
    this.hidePasswordLabel,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.helperText,
    this.maxLength,
    this.inputFormatters,
  }) : assert(
          !isPassword || (showPasswordLabel != null && hidePasswordLabel != null),
        );

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final bool isPassword;
  final String? showPasswordLabel;
  final String? hidePasswordLabel;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final String? helperText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      obscureText: widget.isPassword && _obscured,
      enableSuggestions: !widget.isPassword,
      autocorrect: !widget.isPassword,
      textCapitalization: widget.textCapitalization,
      enabled: widget.enabled,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.helperText,
        helperMaxLines: 2,
        counterText: '',
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.isPassword
            ? IconButton(
                tooltip: _obscured ? widget.showPasswordLabel : widget.hidePasswordLabel,
                onPressed: () => setState(() => _obscured = !_obscured),
                icon: Icon(
                  _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
              )
            : null,
      ),
    );
  }
}
