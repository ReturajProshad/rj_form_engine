import 'package:flutter/material.dart';
import '../../models/dropdown_item.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';

class RjDropdownField extends StatefulWidget {
  final FieldMeta field;
  final String? value;
  final dynamic parentValue;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(String? value) onChanged;

  const RjDropdownField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.parentValue,
    this.errorText,
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
    // Reload when parent cascade value changes
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
      final items =
          await widget.field.dropdownSource!.resolve(widget.parentValue);
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

    // When this field depends on a parent but parent has no value yet
    if (widget.field.dependsOn != null && widget.parentValue == null) {
      // ignore: deprecated_member_use
      return DropdownButtonFormField<String>(
        value: null,
        items: const [],
        onChanged: null,
        decoration: widget.theme.inputDecoration(
          label: widget.field.label,
          hint: 'Select ${widget.field.dependsOn} first',
          errorText: widget.errorText,
        ),
      );
    }

    return Semantics(
      label: widget.field.label,
      hint: 'Tap to select an option',
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _items.any((e) => e.id == widget.value) ? widget.value : null,
        isExpanded: true,
        decoration: widget.theme.inputDecoration(
          label: widget.field.label,
          hint: widget.field.hint ?? 'Select ${widget.field.label}',
          errorText: widget.errorText,
        ),
        style: widget.theme.inputStyle ??
            const TextStyle(fontSize: 14, color: Color(0xFF111827)),
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
        onChanged: widget.onChanged,
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
