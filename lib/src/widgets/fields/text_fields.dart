import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';

class RjTextField extends StatefulWidget {
  final FieldMeta field;
  final dynamic value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(String value) onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;
  final int maxLines;

  const RjTextField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.errorText,
    this.onTap,
    this.readOnly = false,
    this.controller,
    this.maxLines = 1,
  });

  @override
  State<RjTextField> createState() => _RjTextFieldState();
}

class _RjTextFieldState extends State<RjTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      _controller = TextEditingController(
        text: widget.value?.toString() ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(RjTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync external value changes without disturbing cursor
    if (_ownsController) {
      final newText = widget.value?.toString() ?? '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: widget.field.obscureText,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLines: widget.field.type == FieldType.textArea ? widget.field.maxLines : 1,
      style: widget.theme.inputStyle ?? const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      keyboardType: widget.field.type == FieldType.textArea ? TextInputType.multiline : TextInputType.text,
      decoration: widget.theme.inputDecoration(
        label: widget.field.label,
        hint: widget.field.hint,
        errorText: widget.errorText,
        isFocused: _isFocused,
        suffixIcon: widget.readOnly ? const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)) : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}

class RjNumberField extends StatefulWidget {
  final FieldMeta field;
  final dynamic value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(num? value) onChanged;

  const RjNumberField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.errorText,
  });

  @override
  State<RjNumberField> createState() => _RjNumberFieldState();
}

class _RjNumberFieldState extends State<RjNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(RjNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newText = widget.value?.toString() ?? '';
    if (_controller.text != newText && !_isFocused) {
      _controller.text = newText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?[\d]*\.?[\d]*')),
      ],
      style: widget.theme.inputStyle ?? const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: widget.theme.inputDecoration(
        label: widget.field.label,
        hint: widget.field.hint,
        errorText: widget.errorText,
        isFocused: _isFocused,
      ),
      onChanged: (v) => widget.onChanged(num.tryParse(v)),
    );
  }
}
