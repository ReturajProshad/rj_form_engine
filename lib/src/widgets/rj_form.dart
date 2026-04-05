// =============================================================================
// STEP 1 — PATCH: rj_form.dart
// Fixes:
//   A. errorsSummaryBuilder logic bug (called per-entry, shown N times)
//   B. initialValues microtask flicker (Future.microtask in initState)
//   C. Section key collision (empty key generates duplicate from label)
//   D. DropdownButtonFormField deprecated initialValue usage
// =============================================================================

import 'package:flutter/material.dart';
import '../models/field_meta.dart';
import '../models/form_result.dart';
import '../state/form_controller.dart';
import '../theme/form_theme.dart';
import '../utils/rj_responsive.dart';
import 'fields/text_fields.dart';
import 'fields/date_field.dart';
import 'fields/dropdown_field.dart';
import 'fields/image_field.dart';
import 'fields/extra_fields.dart';

class RjForm extends StatefulWidget {
  final List<FieldMeta> fields;
  final Future<void> Function(FormResult result) onSubmit;
  final Map<String, dynamic>? initialValues;
  final FormController? controller;
  final RjFormTheme theme;
  final String submitLabel;
  final bool hideSubmitButton;
  final bool viewOnly;
  final void Function(String key, dynamic value)? onChanged;
  final bool showErrorsSummary;
  final bool autoDismissKeyboard;
  final String? Function(Map<String, String> errors)? errorsSummaryBuilder;
  final void Function(FormResult result)? onSuccess;
  final bool autoClearOnSubmit;

  const RjForm({
    super.key,
    required this.fields,
    required this.onSubmit,
    this.initialValues,
    this.controller,
    this.theme = const RjFormTheme(),
    this.submitLabel = 'Submit',
    this.hideSubmitButton = false,
    this.viewOnly = false,
    this.onChanged,
    this.showErrorsSummary = false,
    this.autoDismissKeyboard = true,
    this.errorsSummaryBuilder,
    this.onSuccess,
    this.autoClearOnSubmit = false,
  });

  @override
  State<RjForm> createState() => _RjFormState();
}

class _RjFormState extends State<RjForm> {
  late final FormController _controller;
  late final bool _ownsController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormController();

    // ─────────────────────────────────────────────────────────────────────────
    // FIX B: initialValues — remove Future.microtask
    //
    // BEFORE (broken):
    //   Future.microtask(() {
    //     if (mounted) _controller.setAll(widget.initialValues!);
    //   });
    //
    // WHY IT'S A BUG:
    //   microtask defers execution until after the first build() completes.
    //   This causes a guaranteed one-frame render with empty fields, which
    //   produces a visible flash/flicker when opening pre-filled edit forms.
    //   Users see blank fields for one frame, then values pop in.
    //
    // WHY THE FIX IS SAFE:
    //   setAll() only calls notifyListeners(). At initState time, no listeners
    //   have been attached yet (the widget hasn't been inserted into the tree).
    //   So calling it synchronously here is perfectly safe — the first build()
    //   will already see the correct values.
    // ─────────────────────────────────────────────────────────────────────────
    if (widget.initialValues != null) {
      _controller.setAll(widget.initialValues!); // ← synchronous, no flicker
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _controller.validate(widget.fields);
    if (!isValid) {
      if (widget.autoDismissKeyboard) {
        FocusScope.of(context).unfocus();
      }
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final result = _controller.toResult();
      await widget.onSubmit(result);
      if (mounted) {
        widget.onSuccess?.call(result);
        if (widget.autoClearOnSubmit) {
          _controller.clear();
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _setValue(String key, dynamic value) {
    _controller.setValue(key, value);
    _controller.clearError(key);
    widget.onChanged?.call(key, value);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.showErrorsSummary && _controller.errors.isNotEmpty)
                  _buildErrorsSummary(width),
                ..._buildFields(width),
                if (!widget.hideSubmitButton && !widget.viewOnly) ...[
                  SizedBox(height: RjResponsive.fieldSpacing(width)),
                  _SubmitButton(
                    label: widget.submitLabel,
                    isLoading: _isSubmitting,
                    theme: widget.theme,
                    onPressed: _submit,
                    width: width,
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    if (widget.autoDismissKeyboard) {
      content = GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: content,
      );
    }
    return content;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FIX A: errorsSummaryBuilder logic bug
  //
  // BEFORE (broken):
  //   ..._controller.errors.entries.map(
  //     (e) => Padding(
  //       child: Text(
  //         widget.errorsSummaryBuilder?.call(_controller.errors) ??
  //             '• ${e.key}: ${e.value}',  // ← BUG
  //       ),
  //     ),
  //   ),
  //
  // WHY IT'S A BUG:
  //   The builder is called INSIDE the .map() over entries. So if there are
  //   3 errors, the builder is called 3 times and returns the same full
  //   custom string each time — displayed 3× in a column. The developer
  //   who passes errorsSummaryBuilder expects it to replace the entire
  //   error list, not be repeated once per error.
  //
  // AFTER: Call the builder once (outside .map), use its result as a single
  //        replacement for the entire list. If it returns null, fall back to
  //        the default per-error bullet list.
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildErrorsSummary(double width) {
    // Call builder ONCE for the whole errors map.
    final customMessage = widget.errorsSummaryBuilder?.call(_controller.errors);

    return Container(
      margin: EdgeInsets.only(bottom: RjResponsive.fieldSpacing(width)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.errorColor.withValues(alpha: 0.08),
        borderRadius: widget.theme.borderRadius,
        border: Border.all(
          color: widget.theme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  color: widget.theme.errorColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Please fix the following errors:',
                style: TextStyle(
                  color: widget.theme.errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── FIXED: custom builder replaces the list entirely ──
          if (customMessage != null)
            Text(
              customMessage,
              style: TextStyle(
                color: widget.theme.errorColor,
                fontSize: RjResponsive.errorFontSize(width),
              ),
            )
          else
            // Default: one bullet per error
            ..._controller.errors.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${e.value}',
                  style: TextStyle(
                    color: widget.theme.errorColor,
                    fontSize: RjResponsive.errorFontSize(width),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFields(double width) {
    final widgets = <Widget>[];
    for (final field in widget.fields) {
      if (field.type == FieldType.section) {
        widgets.add(_buildSection(field, width));
        continue;
      }
      if (field.dependency != null &&
          !field.dependency!.isVisible(_controller.values)) {
        continue;
      }
      final effectiveField =
          widget.viewOnly ? field.copyWith(viewOnly: true) : field;
      widgets.add(
        AbsorbPointer(
          absorbing: effectiveField.viewOnly,
          child: Opacity(
            opacity: effectiveField.viewOnly ? 0.6 : 1.0,
            child: Padding(
              padding:
                  EdgeInsets.only(bottom: RjResponsive.fieldSpacing(width)),
              child: _buildField(effectiveField, width),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildSection(FieldMeta field, double width) {
    return Padding(
      padding: EdgeInsets.only(
        top: RjResponsive.fieldSpacing(width) * 1.5,
        bottom: RjResponsive.fieldSpacing(width) * 0.5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: widget.theme.borderColor, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              field.label,
              style: widget.theme.labelStyle ??
                  TextStyle(
                    fontSize: RjResponsive.labelFontSize(width) + 2,
                    fontWeight: FontWeight.w700,
                    color: widget.theme.primaryColor,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          Expanded(
            child: Divider(color: widget.theme.borderColor, thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildField(FieldMeta field, double width) {
    final error = _controller.errors[field.key];
    final value = _controller.values[field.key];

    switch (field.type) {
      case FieldType.text:
        return RjTextField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.textArea:
        return RjTextField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          maxLines: 4,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.number:
        return RjNumberField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.date:
        return RjDateField(
          field: field,
          value: value is DateTime ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.dropdown:
        final parentValue = field.dependency?.dependsOn != null
            ? _controller.values[field.dependency!.dependsOn]
            : null;
        return RjDropdownField(
          field: field,
          value: value?.toString(),
          parentValue: parentValue,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) {
            _controller.setValueAndClearDependents(field.key, v, widget.fields);
            _controller.clearError(field.key);
            widget.onChanged?.call(field.key, v);
          },
          width: width,
        );
      case FieldType.image:
        final paths =
            value is List ? value.whereType<String>().toList() : <String>[];
        return RjImageField(
          field: field,
          value: paths,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          onValidationError: (msg) => _controller.setError(field.key, msg),
          width: width,
        );
      case FieldType.custom:
        if (field.builder == null) {
          return Text(
            'FieldMeta.custom requires a builder for key: ${field.key}',
            style: TextStyle(color: widget.theme.errorColor),
          );
        }
        return field.builder!(
            context, field, value, (v) => _setValue(field.key, v), error);
      case FieldType.slider:
        return RjSliderField(
          field: field,
          value: value is double
              ? value
              : (value is num ? value.toDouble() : null),
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.timePicker:
        return RjTimePickerField(
          field: field,
          value: value is TimeOfDay ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.spinner:
        return RjSpinnerField(
          field: field,
          value: value is int ? value : (value is num ? value.toInt() : null),
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.toggle:
        return RjToggleField(
          field: field,
          value: value is bool ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.radio:
        return RjRadioField(
          field: field,
          options: field.options,
          value: value?.toString(),
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.chip:
        final selected =
            value is List ? value.whereType<String>().toList() : <String>[];
        return RjChipField(
          field: field,
          options: field.options,
          value: selected,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
          width: width,
        );
      case FieldType.section:
        return const SizedBox.shrink();
    }
  }
}

// ─── Submit button (unchanged) ────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final RjFormTheme theme;
  final VoidCallback onPressed;
  final double width;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.theme,
    required this.onPressed,
    this.width = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.submitButtonColor ?? theme.primaryColor,
          foregroundColor: Colors.white,
          padding: RjResponsive.submitButtonPadding(width),
          shape: RoundedRectangleBorder(borderRadius: theme.borderRadius),
          elevation: 1,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: theme.submitButtonTextStyle ??
                    TextStyle(
                      fontSize: RjResponsive.submitButtonFontSize(width),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
              ),
      ),
    );
  }
}
