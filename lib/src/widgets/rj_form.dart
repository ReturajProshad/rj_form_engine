// =============================================================================
// STEP 3 — PERFORMANCE REFACTOR
// Problem: Entire form rebuilds on every keystroke
// Solution: Per-field rebuild using FormFieldScope (InheritedWidget pattern)
// =============================================================================

import 'package:flutter/material.dart';
import '../models/field_meta.dart';
import '../models/form_result.dart';
import '../models/rj_error_key.dart';
import '../state/form_controller.dart';
import '../theme/form_theme.dart';
import '../utils/rj_grid.dart';
import '../utils/rj_responsive.dart';
import 'fields/field_widget.dart';
import 'fields/group_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// _FormScope — InheritedWidget to propagate controller without rebuilding
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
  final double flex; // proportion of row width (0.0-1.0)
  final void Function(String key, dynamic value) setValue;
  final void Function(
    String key,
    dynamic value,
    List<FieldMeta> fields, {
    Map<String, dynamic> extraValues,
  }) setValueCascade;
  final void Function(String key, String message) setError;

  const _FieldBuilder({
    required this.field,
    required this.width,
    this.flex = 1.0,
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
    _lastValue = _controller?.rawValue(widget.field.key);
    _lastError = _controller?.rawError(widget.field.key);
    _lastParentValue = widget.field.dependency != null
        ? _controller?.rawValue(widget.field.dependency!.dependsOn)
        : null;
  }

  void _onControllerChanged() {
    final currentValue = _controller?.rawValue(widget.field.key);
    final currentError = _controller?.rawError(widget.field.key);
    final currentParentValue = widget.field.dependency != null
        ? _controller?.rawValue(widget.field.dependency!.dependsOn)
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
        !field.dependency!.isVisible(_controller?.rawState ?? {})) {
      return const SizedBox.shrink();
    }

    final isDerived = field.derivation != null;
    final isViewOnly = scope.viewOnly;
    final effectiveField = isViewOnly ? field.copyWith(viewOnly: true) : field;
    // When labelConfig is set, suppress default label in the field widget
    // so the custom label (rendered above) doesn't conflict.
    final fieldForWidget =
        effectiveField.labelConfig != null && effectiveField.showLabel
            ? effectiveField.copyWith(showLabel: false)
            : effectiveField;
    final absorbing = effectiveField.viewOnly || isDerived;

    Widget fieldWidget = _buildFieldWidget(fieldForWidget, scope);

    // Render custom labelConfig above the field when showLabel is true
    if (effectiveField.showLabel && effectiveField.labelConfig != null) {
      final config = effectiveField.labelConfig!;
      Widget labelWidget;
      if (config is RjLabelText) {
        labelWidget = Padding(
          padding: config.padding ?? EdgeInsets.zero,
          child: Text(
            config.text,
            style: config.style,
            textAlign: config.textAlign,
            maxLines: config.maxLines,
            overflow: config.overflow,
          ),
        );
      } else if (config is RjLabelCustom) {
        labelWidget = config.builder(context);
      } else {
        labelWidget = const SizedBox.shrink();
      }
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labelWidget,
          SizedBox(height: RjResponsive.fieldSpacing(widget.width) * 0.4),
          fieldWidget,
        ],
      );
    }

    return AbsorbPointer(
      absorbing: absorbing,
      child: Opacity(
        opacity: effectiveField.viewOnly ? 0.6 : 1.0,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: RjResponsive.fieldSpacing(widget.width)),
          child: fieldWidget,
        ),
      ),
    );
  }

  Widget _buildFieldWidget(FieldMeta field, _FormScope scope) {
    final error = _lastError;
    final value = _lastValue;
    final width = widget.width;
    final theme = scope.theme;

    if (field.type == FieldType.group) {
      return RjGroupField(
        field: field,
        width: width,
        controller: scope.controller,
        formFields: scope.fields,
        theme: theme,
        viewOnly: scope.viewOnly,
        onChanged: scope.onChanged,
      );
    }

    return buildFieldWidget(
      context: context,
      field: field,
      value: value,
      error: error,
      theme: theme,
      width: width,
      parentValue: _lastParentValue,
      onChange: (v) => widget.setValue(field.key, v),
      onCascadeChange: (v, {label}) {
        final extra = <String, dynamic>{};
        if (label != null) extra['${field.key}Label'] = label;
        widget.setValueCascade(
          field.key,
          v,
          scope.fields,
          extraValues: extra,
        );
      },
      onImageValidationError: (msg) => widget.setError(field.key, msg),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. _ErrorSummaryListener — only rebuilds when error map changes
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorSummaryListener extends StatefulWidget {
  final RjFormTheme theme;
  final String? Function(Map<String, String> errors)? errorsSummaryBuilder;
  final double width;
  final List<FieldMeta> fields;

  const _ErrorSummaryListener({
    required this.theme,
    required this.width,
    required this.fields,
    this.errorsSummaryBuilder,
  });

  @override
  State<_ErrorSummaryListener> createState() => _ErrorSummaryListenerState();
}

class _ErrorSummaryListenerState extends State<_ErrorSummaryListener> {
  FormController? _controller;
  Map<String, String> _lastErrors = {};
  int _lastGroupVersion = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = _FormScope.of(context).controller;
    if (_controller == null || !identical(_controller, newController)) {
      _controller?.removeListener(_onChanged);
      _controller = newController;
      _controller!.addListener(_onChanged);
      _lastErrors = Map.from(_controller!.errors);
      _lastGroupVersion = _controller!.groupVersion;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final errors = _controller?.errors ?? {};
    final groupVersion = _controller?.groupVersion ?? 0;
    if (errors.length != _lastErrors.length ||
        errors.entries.any((e) => _lastErrors[e.key] != e.value) ||
        groupVersion != _lastGroupVersion) {
      setState(() {
        _lastErrors = Map.from(errors);
        _lastGroupVersion = groupVersion;
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
            ..._lastErrors.entries.map((e) {
              final parsed = RjErrorKey.tryParse(e.key);
              final label = _groupErrorLabel(parsed);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $label${e.value}',
                  style: TextStyle(
                    color: theme.errorColor,
                    fontSize: RjResponsive.errorFontSize(widget.width),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Resolves a "Row N — " prefix for composite group error keys.
  /// Custom [errorsSummaryBuilder]s receive the raw map with composite keys
  /// and can use [RjErrorKey.tryParse] themselves.
  String _groupErrorLabel(RjErrorKey? key) {
    if (key == null) return '';
    String groupLabel = key.groupKey;
    for (final f in widget.fields) {
      if (f.key == key.groupKey) {
        groupLabel = f.label;
        break;
      }
    }
    final idx = _controller?.groupIndexForId(key.groupKey, key.rowId) ?? -1;
    return idx >= 0 ? '$groupLabel — Row ${idx + 1}: ' : '$groupLabel: ';
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
      _controller.recomputeAllDerivations(widget.fields);
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _setValue(String key, dynamic value) {
    _controller.setValueWithDerivation(key, value, widget.fields);
    _controller.clearError(key);
    _controller.clearDerivedFieldErrors(key, widget.fields);
    widget.onChanged?.call(key, value);
  }

  void _setValueCascade(
    String key,
    dynamic value,
    List<FieldMeta> fields, {
    Map<String, dynamic> extraValues = const {},
  }) {
    _controller.setValueAndClearDependents(
      key,
      value,
      fields,
      extraValues: extraValues,
    );
    _controller.clearError(key);
    _controller.clearDerivedFieldErrors(key, widget.fields);
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
                  fields: widget.fields,
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
    return buildResponsiveGrid(
      width: width,
      theme: widget.theme,
      fields: widget.fields,
      fieldBuilder: (field, flex) => _FieldBuilder(
        key: ValueKey(field.key),
        field: field,
        width: width,
        flex: flex,
        setValue: _setValue,
        setValueCascade: _setValueCascade,
        setError: _controller.setError,
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
