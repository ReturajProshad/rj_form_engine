import 'package:flutter/material.dart';

/// Defines the visual appearance of all fields rendered by [RjForm].
///
/// Pass a custom [RjFormTheme] to [RjForm.theme] to override any defaults.
///
/// Example:
/// ```dart
/// RjForm(
///   fields: fields,
///   theme: RjFormTheme(
///     primaryColor: Colors.teal,
///     borderRadius: BorderRadius.circular(16),
///     fieldSpacing: 24,
///   ),
///   onSubmit: (_) async {},
/// )
/// ```
class RjFormTheme {
  /// Primary accent color — used for focused borders, date picker, etc.
  final Color primaryColor;

  /// Default border color when a field is not focused and has no error.
  final Color borderColor;

  /// Border color when a field has a validation error.
  final Color errorColor;

  /// Border color when a field is focused.
  final Color focusedBorderColor;

  /// Background fill color for all fields.
  final Color fieldFillColor;

  /// Text style for field labels.
  final TextStyle? labelStyle;

  /// Text style for field input text.
  final TextStyle? inputStyle;

  /// Text style for validation error messages.
  final TextStyle? errorStyle;

  /// Text style for hint text.
  final TextStyle? hintStyle;

  /// Border radius applied to all fields and image containers.
  final BorderRadius borderRadius;

  /// Vertical spacing between consecutive fields.
  final double fieldSpacing;

  /// Border width for all field outlines.
  final double borderWidth;

  /// Content padding inside each field.
  final EdgeInsets contentPadding;

  /// Background color of the submit button.
  final Color? submitButtonColor;

  /// Text style for the submit button label.
  final TextStyle? submitButtonTextStyle;

  const RjFormTheme({
    this.primaryColor = const Color(0xFF2563EB),
    this.borderColor = const Color(0xFFD1D5DB),
    this.errorColor = const Color(0xFFDC2626),
    this.focusedBorderColor = const Color(0xFF2563EB),
    this.fieldFillColor = const Color(0xFFF9FAFB),
    this.labelStyle,
    this.inputStyle,
    this.errorStyle,
    this.hintStyle,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.fieldSpacing = 20,
    this.borderWidth = 1.5,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    this.submitButtonColor,
    this.submitButtonTextStyle,
  });

  /// Returns an [InputDecoration] pre-configured with this theme's values.
  InputDecoration inputDecoration({
    required String label,
    String? hint,
    String? errorText,
    bool isFocused = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: fieldFillColor,
      contentPadding: contentPadding,
      labelStyle: labelStyle ??
          TextStyle(
            color: isFocused ? focusedBorderColor : const Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
      hintStyle: hintStyle ??
          const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      errorStyle: errorStyle ??
          TextStyle(color: errorColor, fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor, width: borderWidth),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide:
            BorderSide(color: focusedBorderColor, width: borderWidth + 0.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: errorColor, width: borderWidth),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: errorColor, width: borderWidth + 0.5),
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
    );
  }

  /// Creates a copy with specific fields overridden.
  RjFormTheme copyWith({
    Color? primaryColor,
    Color? borderColor,
    Color? errorColor,
    Color? focusedBorderColor,
    Color? fieldFillColor,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextStyle? errorStyle,
    TextStyle? hintStyle,
    BorderRadius? borderRadius,
    double? fieldSpacing,
    double? borderWidth,
    EdgeInsets? contentPadding,
    Color? submitButtonColor,
    TextStyle? submitButtonTextStyle,
  }) {
    return RjFormTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      borderColor: borderColor ?? this.borderColor,
      errorColor: errorColor ?? this.errorColor,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      fieldFillColor: fieldFillColor ?? this.fieldFillColor,
      labelStyle: labelStyle ?? this.labelStyle,
      inputStyle: inputStyle ?? this.inputStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      hintStyle: hintStyle ?? this.hintStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      borderWidth: borderWidth ?? this.borderWidth,
      contentPadding: contentPadding ?? this.contentPadding,
      submitButtonColor: submitButtonColor ?? this.submitButtonColor,
      submitButtonTextStyle:
          submitButtonTextStyle ?? this.submitButtonTextStyle,
    );
  }
}
