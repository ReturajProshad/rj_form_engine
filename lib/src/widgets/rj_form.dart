import 'package:flutter/material.dart';
import '../models/field_meta.dart';
import '../models/form_result.dart';
import '../state/form_controller.dart';
import '../theme/form_theme.dart';
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

    if (widget.initialValues != null) {
      Future.microtask(() {
        if (mounted) _controller.setAll(widget.initialValues!);
      });
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
      await widget.onSubmit(_controller.toResult());
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
    Widget content = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showErrorsSummary && _controller.errors.isNotEmpty)
              _buildErrorsSummary(),
            ..._buildFields(),
            if (!widget.hideSubmitButton && !widget.viewOnly) ...[
              SizedBox(height: widget.theme.fieldSpacing),
              _SubmitButton(
                label: widget.submitLabel,
                isLoading: _isSubmitting,
                theme: widget.theme,
                onPressed: _submit,
              ),
            ],
          ],
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

  Widget _buildErrorsSummary() {
    return Container(
      margin: EdgeInsets.only(bottom: widget.theme.fieldSpacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.theme.errorColor.withOpacity(0.08),
        borderRadius: widget.theme.borderRadius,
        border: Border.all(
          color: widget.theme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: widget.theme.errorColor,
                size: 18,
              ),
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
          ..._controller.errors.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.errorsSummaryBuilder?.call(_controller.errors) ??
                    '• ${e.key}: ${e.value}',
                style: TextStyle(
                  color: widget.theme.errorColor,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFields() {
    final widgets = <Widget>[];

    for (final field in widget.fields) {
      if (field.dependency != null &&
          !field.dependency!.isVisible(_controller.values)) {
        continue;
      }

      final effectiveField =
          widget.viewOnly ? field.copyWith(viewOnly: true) : field;

      final fieldWidget = _buildField(effectiveField);

      widgets.add(
        AbsorbPointer(
          absorbing: effectiveField.viewOnly,
          child: Opacity(
            opacity: effectiveField.viewOnly ? 0.6 : 1.0,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.theme.fieldSpacing),
              child: fieldWidget,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildField(FieldMeta field) {
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
        );

      case FieldType.textArea:
        return RjTextField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          maxLines: 4,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.number:
        return RjNumberField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.date:
        return RjDateField(
          field: field,
          value: value is DateTime ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.dropdown:
        final parentValue = field.dependsOn != null
            ? _controller.values[field.dependsOn]
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
        );

      case FieldType.custom:
        if (field.builder == null) {
          return Text(
            'FieldMeta.custom requires a builder for key: ${field.key}',
            style: TextStyle(color: widget.theme.errorColor),
          );
        }
        return field.builder!(
          context,
          value,
          (v) => _setValue(field.key, v),
          error,
        );

      case FieldType.slider:
        return RjSliderField(
          field: field,
          value: value is double
              ? value
              : (value is num ? value.toDouble() : null),
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.timePicker:
        return RjTimePickerField(
          field: field,
          value: value is TimeOfDay ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.spinner:
        return RjSpinnerField(
          field: field,
          value: value is int ? value : (value is num ? value.toInt() : null),
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.toggle:
        return RjToggleField(
          field: field,
          value: value is bool ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
        );

      case FieldType.radio:
        return RjRadioField(
          field: field,
          options: field.options,
          value: value?.toString(),
          errorText: error,
          theme: widget.theme,
          onChanged: (v) => _setValue(field.key, v),
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
        );
    }
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final RjFormTheme theme;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.theme,
    required this.onPressed,
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: theme.borderRadius,
          ),
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
                    const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
              ),
      ),
    );
  }
}
