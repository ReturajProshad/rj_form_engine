// =============================================================================
// STEP 3 — PERFORMANCE REFACTOR
// Problem: Entire form rebuilds on every keystroke
// Solution: Per-field rebuild using FormFieldScope (InheritedWidget pattern)
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

// ─────────────────────────────────────────────────────────────────────────────
// 1. _FormScope — InheritedWidget to propagate controller without rebuilding
// ─────────────────────────────────────────────────────────────────────────────

class _FormScope extends InheritedWidget {
  final FormController controller;
  final RjFormTheme theme;
  final List<FieldMeta> fields;
  final bool viewOnly;
  final void Function(String key, dynamic value)? onChanged;

  const _FormScope({
    required this.controller,
    required this.theme,
    required this.fields,
    required this.viewOnly,
    required this.onChanged,
    required super.child,
  });

  @override
  bool updateShouldNotify(_FormScope oldWidget) => false;

  static _FormScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_FormScope>();
    assert(scope != null, '_FormScope not found in widget tree');
    return scope!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. _FieldBuilder — rebuilds ONLY when its own value or error changes
// ─────────────────────────────────────────────────────────────────────────────

class _FieldBuilder extends StatefulWidget {
  final FieldMeta field;
  final double width;
  final void Function(String key, dynamic value) setValue;
  final void Function(String key, dynamic value, List<FieldMeta> fields)
      setValueCascade;
  final void Function(String key, String message) setError;

  const _FieldBuilder({
    required this.field,
    required this.width,
    required this.setValue,
    required this.setValueCascade,
    required this.setError,
    super.key,
  });

  @override
  State<_FieldBuilder> createState() => _FieldBuilderState();
}

class _FieldBuilderState extends State<_FieldBuilder> {
  FormController? _controller;
  dynamic _lastValue;
  String? _lastError;
  dynamic _lastParentValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = _FormScope.of(context);
    final newController = scope.controller;

    if (_controller == null || !identical(_controller, newController)) {
      _controller?.removeListener(_onControllerChanged);
      _controller = newController;
      _controller!.addListener(_onControllerChanged);
      _syncState();
    }
  }

  @override
  void didUpdateWidget(_FieldBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.key != widget.field.key) {
      _syncState();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _syncState() {
    _lastValue = _controller?.values[widget.field.key];
    _lastError = _controller?.errors[widget.field.key];
    _lastParentValue = widget.field.dependency != null
        ? _controller?.values[widget.field.dependency!.dependsOn]
        : null;
  }

  void _onControllerChanged() {
    final currentValue = _controller?.values[widget.field.key];
    final currentError = _controller?.errors[widget.field.key];
    final currentParentValue = widget.field.dependency != null
        ? _controller?.values[widget.field.dependency!.dependsOn]
        : null;

    final valueChanged = currentValue != _lastValue;
    final errorChanged = currentError != _lastError;
    final parentChanged = currentParentValue != _lastParentValue;

    if (valueChanged || errorChanged || parentChanged) {
      setState(() {
        _lastValue = currentValue;
        _lastError = currentError;
        _lastParentValue = currentParentValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = _FormScope.of(context);
    final field = widget.field;

    if (field.dependency != null &&
        !field.dependency!.isVisible(_controller?.values ?? {})) {
      return const SizedBox.shrink();
    }

    final effectiveField =
        scope.viewOnly ? field.copyWith(viewOnly: true) : field;

    return AbsorbPointer(
      absorbing: effectiveField.viewOnly,
      child: Opacity(
        opacity: effectiveField.viewOnly ? 0.6 : 1.0,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: RjResponsive.fieldSpacing(widget.width)),
          child: _buildFieldWidget(effectiveField, scope),
        ),
      ),
    );
  }

  Widget _buildFieldWidget(FieldMeta field, _FormScope scope) {
    final error = _lastError;
    final value = _lastValue;
    final width = widget.width;
    final theme = scope.theme;

    switch (field.type) {
      case FieldType.text:
        return RjTextField(
          field: field,
          value: value,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.textArea:
        return RjTextField(
          field: field,
          value: value,
          errorText: error,
          theme: theme,
          maxLines: 4,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.number:
        return RjNumberField(
          field: field,
          value: value,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.date:
        return RjDateField(
          field: field,
          value: value is DateTime ? value : null,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.dropdown:
        return RjDropdownField(
          field: field,
          value: value?.toString(),
          parentValue: _lastParentValue,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValueCascade(field.key, v, scope.fields),
          width: width,
        );

      case FieldType.image:
        final paths =
            value is List ? value.whereType<String>().toList() : <String>[];
        return RjImageField(
          field: field,
          value: paths,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          onValidationError: (msg) => widget.setError(field.key, msg),
          width: width,
        );

      case FieldType.custom:
        if (field.builder == null) {
          return Text(
            'FieldMeta.custom requires a builder for key: ${field.key}',
            style: TextStyle(color: theme.errorColor),
          );
        }
        return field.builder!(
          context,
          field,
          value,
          (v) => widget.setValue(field.key, v),
          error,
        );

      case FieldType.slider:
        return RjSliderField(
          field: field,
          value: value is double
              ? value
              : (value is num ? value.toDouble() : null),
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.timePicker:
        return RjTimePickerField(
          field: field,
          value: value is TimeOfDay ? value : null,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.spinner:
        return RjSpinnerField(
          field: field,
          value: value is int ? value : (value is num ? value.toInt() : null),
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.toggle:
        return RjToggleField(
          field: field,
          value: value is bool ? value : null,
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.radio:
        return RjRadioField(
          field: field,
          options: field.options,
          value: value?.toString(),
          errorText: error,
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
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
          theme: theme,
          onChanged: (v) => widget.setValue(field.key, v),
          width: width,
        );

      case FieldType.section:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. _ErrorSummaryListener — only rebuilds when error map changes
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorSummaryListener extends StatefulWidget {
  final RjFormTheme theme;
  final String? Function(Map<String, String> errors)? errorsSummaryBuilder;
  final double width;

  const _ErrorSummaryListener({
    required this.theme,
    required this.width,
    this.errorsSummaryBuilder,
  });

  @override
  State<_ErrorSummaryListener> createState() => _ErrorSummaryListenerState();
}

class _ErrorSummaryListenerState extends State<_ErrorSummaryListener> {
  FormController? _controller;
  Map<String, String> _lastErrors = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = _FormScope.of(context).controller;
    if (_controller == null || !identical(_controller, newController)) {
      _controller?.removeListener(_onChanged);
      _controller = newController;
      _controller!.addListener(_onChanged);
      _lastErrors = Map.from(_controller!.errors);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final errors = _controller?.errors ?? {};
    if (errors.length != _lastErrors.length ||
        errors.entries.any((e) => _lastErrors[e.key] != e.value)) {
      setState(() {
        _lastErrors = Map.from(errors);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastErrors.isEmpty) return const SizedBox.shrink();

    final customMessage = widget.errorsSummaryBuilder?.call(_lastErrors);
    final theme = widget.theme;

    return Container(
      margin: EdgeInsets.only(bottom: RjResponsive.fieldSpacing(widget.width)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.errorColor.withValues(alpha: 0.08),
        borderRadius: theme.borderRadius,
        border: Border.all(color: theme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: theme.errorColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Please fix the following errors:',
                style: TextStyle(
                  color: theme.errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (customMessage != null)
            Text(
              customMessage,
              style: TextStyle(
                color: theme.errorColor,
                fontSize: RjResponsive.errorFontSize(widget.width),
              ),
            )
          else
            ..._lastErrors.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${e.value}',
                  style: TextStyle(
                    color: theme.errorColor,
                    fontSize: RjResponsive.errorFontSize(widget.width),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. _SubmittingListener — only rebuilds when isSubmitting changes
// ─────────────────────────────────────────────────────────────────────────────

class _SubmittingListener extends StatefulWidget {
  final ValueNotifier<bool> isSubmitting;
  final String label;
  final RjFormTheme theme;
  final VoidCallback onPressed;
  final double width;

  const _SubmittingListener({
    required this.isSubmitting,
    required this.label,
    required this.theme,
    required this.onPressed,
    required this.width,
  });

  @override
  State<_SubmittingListener> createState() => _SubmittingListenerState();
}

class _SubmittingListenerState extends State<_SubmittingListener> {
  @override
  void initState() {
    super.initState();
    widget.isSubmitting.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(_SubmittingListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSubmitting != widget.isSubmitting) {
      oldWidget.isSubmitting.removeListener(_onChanged);
      widget.isSubmitting.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.isSubmitting.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return _SubmitButton(
      label: widget.label,
      isLoading: widget.isSubmitting.value,
      theme: widget.theme,
      onPressed: widget.onPressed,
      width: widget.width,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. RjForm — updated to use _FormScope + _FieldBuilder
// ─────────────────────────────────────────────────────────────────────────────

class RjForm extends StatefulWidget {
  final List<FieldMeta> fields;
  final Future<void> Function(FormResult result)? onSubmit;
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
    this.onSubmit,
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

  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? FormController();

    if (widget.initialValues != null) {
      _controller.setAll(widget.initialValues!);
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _setValue(String key, dynamic value) {
    _controller.setValue(key, value);
    _controller.clearError(key);
    widget.onChanged?.call(key, value);
  }

  void _setValueCascade(String key, dynamic value, List<FieldMeta> fields) {
    _controller.setValueAndClearDependents(key, value, fields);
    _controller.clearError(key);
    widget.onChanged?.call(key, value);
  }

  Future<void> _submit() async {
    if (widget.onSubmit == null) return;
    final isValid = _controller.validate(widget.fields);
    if (!isValid) {
      if (widget.autoDismissKeyboard) FocusScope.of(context).unfocus();
      return;
    }
    _isSubmitting.value = true;
    try {
      final result = _controller.toResult();
      await widget.onSubmit!(result);
      if (mounted) {
        widget.onSuccess?.call(result);
        if (widget.autoClearOnSubmit) _controller.clear();
      }
    } finally {
      if (mounted) _isSubmitting.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = _FormScope(
      controller: _controller,
      theme: widget.theme,
      fields: widget.fields,
      viewOnly: widget.viewOnly,
      onChanged: widget.onChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showErrorsSummary)
                _ErrorSummaryListener(
                  theme: widget.theme,
                  width: width,
                  errorsSummaryBuilder: widget.errorsSummaryBuilder,
                ),
              ..._buildFieldList(width),
              if (!widget.hideSubmitButton &&
                  !widget.viewOnly &&
                  widget.onSubmit != null) ...[
                SizedBox(height: RjResponsive.fieldSpacing(width)),
                _SubmittingListener(
                  isSubmitting: _isSubmitting,
                  label: widget.submitLabel,
                  theme: widget.theme,
                  onPressed: _submit,
                  width: width,
                ),
              ],
            ],
          );
        },
      ),
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

  List<Widget> _buildFieldList(double width) {
    final widgets = <Widget>[];
    for (final field in widget.fields) {
      if (field.type == FieldType.section) {
        widgets.add(_buildSection(field, width));
        continue;
      }

      widgets.add(
        _FieldBuilder(
          key: ValueKey(field.key),
          field: field,
          width: width,
          setValue: _setValue,
          setValueCascade: _setValueCascade,
          setError: _controller.setError,
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
              child: Divider(color: widget.theme.borderColor, thickness: 1)),
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
              child: Divider(color: widget.theme.borderColor, thickness: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubmitButton (unchanged internal widget)
// ─────────────────────────────────────────────────────────────────────────────

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
