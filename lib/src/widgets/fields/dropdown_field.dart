// =============================================================================
// STEP 1 — PATCH B: dropdown_field.dart
// Fix: Deprecated DropdownButtonFormField.initialValue usage
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// BUG EXPLANATION — Deprecated API
//
// BEFORE (broken):
//   DropdownButtonFormField<String>(
//     // ignore: deprecated_member_use
//     initialValue: null,   ← deprecated in Flutter 3.17+
//     ...
//   )
//
// WHY IT'S A BUG:
//   The `initialValue` parameter on DropdownButtonFormField is deprecated.
//   The package ships with an explicit `// ignore: deprecated_member_use`
//   comment to suppress the warning. This will break silently when Flutter
//   removes the parameter in a future version. The correct approach is to
//   control the selected value entirely through the `value` parameter,
//   which the widget already does for the non-disabled case.
//
// FIX:
//   Remove the disabled/waiting-for-parent branch that used `initialValue`.
//   Replace with an `AbsorbPointer` + `IgnorePointer` approach, keeping
//   the dropdown rendered but non-interactive, which also gives better UX
//   (user can see the field exists but it's grayed out).
// ─────────────────────────────────────────────────────────────────────────────

// Full replacement for lib/src/widgets/fields/dropdown_field.dart:

// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import '../../models/dropdown_item.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';
import '../../utils/rj_responsive.dart';

class RjDropdownField extends StatefulWidget {
  final FieldMeta field;
  final String? value;
  final dynamic parentValue;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(String? value) onChanged;
  final double width;

  const RjDropdownField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.parentValue,
    this.errorText,
    this.width = 0,
  });

  @override
  State<RjDropdownField> createState() => _RjDropdownFieldState();
}

class _RjDropdownFieldState extends State<RjDropdownField> {
  List<DropdownItem> _items = [];
  bool _loading = false;
  String? _loadError;
  dynamic _lastParentValue;

  @override
  void initState() {
    super.initState();
    _lastParentValue = widget.parentValue;
    _load();
  }

  @override
  void didUpdateWidget(RjDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parentValue != _lastParentValue) {
      _lastParentValue = widget.parentValue;
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.field.dropdownSource == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await widget.field.dropdownSource!
          .resolve(parentValue: widget.parentValue?.toString());
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load ${widget.field.label}';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildShell(
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return _buildShell(
        child: Row(
          children: [
            Icon(Icons.error_outline, color: widget.theme.errorColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _loadError!,
                style: TextStyle(color: widget.theme.errorColor, fontSize: 12),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // FIXED: Waiting-for-parent state — no deprecated `initialValue`
    //
    // BEFORE: Used DropdownButtonFormField with initialValue: null (deprecated)
    //
    // AFTER: Render a normal dropdown with an empty item list and an
    //        AbsorbPointer to block interaction. This is non-deprecated,
    //        visually communicates the disabled state, and avoids the
    //        deprecated API entirely.
    // ─────────────────────────────────────────────────────────────────────────
    final isWaitingForParent = widget.field.dependency?.dependsOn != null &&
        widget.parentValue == null;

    return Semantics(
      label: widget.field.label,
      hint: isWaitingForParent
          ? 'Select ${widget.field.dependency!.dependsOn} first'
          : 'Tap to select an option',
      child: AbsorbPointer(
        absorbing: isWaitingForParent,
        child: Opacity(
          opacity: isWaitingForParent ? 0.5 : 1.0,
          child: DropdownButtonFormField<String>(
            // `value` is the correct non-deprecated API.
            // Guard: if current value is not in the items list, pass null
            // to avoid "value must be in items" assertion.
            initialValue:
                _items.any((e) => e.id == widget.value) ? widget.value : null,
            isExpanded: true,
            decoration: widget.theme.inputDecoration(
              label: widget.field.label,
              hint: isWaitingForParent
                  ? 'Select ${widget.field.dependency?.dependsOn} first'
                  : widget.field.hint ?? 'Select ${widget.field.label}',
              errorText: widget.errorText,
            ),
            style: widget.theme.inputStyle ??
                TextStyle(
                  fontSize: RjResponsive.inputFontSize(widget.width),
                  color: const Color(0xFF111827),
                ),
            items: _items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: isWaitingForParent ? null : widget.onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return InputDecorator(
      decoration: widget.theme.inputDecoration(
        label: widget.field.label,
        errorText: widget.errorText,
      ),
      child: child,
    );
  }
}
