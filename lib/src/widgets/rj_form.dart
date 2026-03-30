import 'package:flutter/material.dart';
import '../models/field_meta.dart';
import '../models/form_result.dart';
import '../state/form_controller.dart';
import '../theme/form_theme.dart';
import 'fields/text_fields.dart';
import 'fields/date_field.dart';
import 'fields/dropdown_field.dart';
import 'fields/image_field.dart';

/// The main form widget of [rj_form_engine].
///
/// Renders a list of [FieldMeta] definitions as a fully functional,
/// validated form. Zero external dependencies — works with any state
/// management or plain StatefulWidget.
///
/// **Basic usage:**
/// ```dart
/// RjForm(
///   fields: [
///     FieldMeta(key: 'name', label: 'Full Name', type: FieldType.text, required: true),
///     FieldMeta(key: 'dob',  label: 'Date of Birth', type: FieldType.date),
///   ],
///   onSubmit: (result) async {
///     print(result.values); // {'name': 'John', 'dob': DateTime(...)}
///   },
/// )
/// ```
///
/// **Pre-filling values (edit mode):**
/// ```dart
/// RjForm(
///   fields: fields,
///   initialValues: {'name': 'John Doe', 'dob': DateTime(1990, 1, 1)},
///   onSubmit: (_) async {},
/// )
/// ```
///
/// **External controller (read values outside the form):**
/// ```dart
/// final _ctrl = FormController();
///
/// RjForm(
///   fields: fields,
///   controller: _ctrl,
///   onSubmit: (_) async {},
/// )
/// ```
///
/// **Custom styling:**
/// ```dart
/// RjForm(
///   fields: fields,
///   theme: RjFormTheme(primaryColor: Colors.teal),
///   onSubmit: (_) async {},
/// )
/// ```
class RjForm extends StatefulWidget {
  /// The list of field definitions to render.
  final List<FieldMeta> fields;

  /// Called with a [FormResult] when validation passes and the user submits.
  /// Make this async to show a loading state on the submit button.
  final Future<void> Function(FormResult result) onSubmit;

  /// Optional pre-filled values. Useful for edit/clone mode.
  final Map<String, dynamic>? initialValues;

  /// Optional external controller. If provided, the form will use this
  /// controller instead of creating its own. You are responsible for
  /// calling [FormController.dispose].
  final FormController? controller;

  /// Visual theme for all fields. Defaults to [RjFormTheme] with sensible values.
  final RjFormTheme theme;

  /// Label for the submit button. Defaults to 'Submit'.
  final String submitLabel;

  /// When true, the submit button is hidden. Useful when you want to
  /// trigger submission externally via [FormController.validate].
  final bool hideSubmitButton;

  /// When true, all fields are rendered as read-only (view mode).
  final bool viewOnly;

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
      // Use microtask to avoid calling notifyListeners during build
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
    if (!isValid) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(_controller.toResult());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fields
            ..._buildFields(),

            // Submit button
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
  }

  List<Widget> _buildFields() {
    final widgets = <Widget>[];

    for (final field in widget.fields) {
      // Visibility check
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
          onChanged: (v) {
            _controller.setValue(field.key, v);
            _controller.clearError(field.key);
          },
        );

      case FieldType.textArea:
        return RjTextField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          maxLines: 4,
          onChanged: (v) {
            _controller.setValue(field.key, v);
            _controller.clearError(field.key);
          },
        );

      case FieldType.number:
        return RjNumberField(
          field: field,
          value: value,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) {
            _controller.setValue(field.key, v);
            _controller.clearError(field.key);
          },
        );

      case FieldType.date:
        return RjDateField(
          field: field,
          value: value is DateTime ? value : null,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) {
            _controller.setValue(field.key, v);
            _controller.clearError(field.key);
          },
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
            _controller.setValueAndClearDependents(
                field.key, v, widget.fields);
            _controller.clearError(field.key);
          },
        );

      case FieldType.image:
        final paths = value is List
            ? value.whereType<String>().toList()
            : <String>[];

        return RjImageField(
          field: field,
          value: paths,
          errorText: error,
          theme: widget.theme,
          onChanged: (v) {
            _controller.setValue(field.key, v);
            _controller.clearError(field.key);
          },
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
          (v) {
            _controller.setValue(field.key, v);
            _controller.clearError(field.key);
          },
          error,
        );
    }
  }
}

// ─── Submit Button ──────────────────────────────────────────────────────────

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
          backgroundColor:
              theme.submitButtonColor ?? theme.primaryColor,
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
