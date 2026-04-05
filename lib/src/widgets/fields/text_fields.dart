import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';
import '../../utils/rj_responsive.dart';

class _NumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final minusCount = text
        .splitMapJoin(
          RegExp(r'-'),
          onMatch: (_) => '-',
          onNonMatch: (_) => '',
        )
        .length;

    if (minusCount > 1) return oldValue;
    if (minusCount == 1 && !text.startsWith('-')) return oldValue;

    final dotCount = text
        .splitMapJoin(
          RegExp(r'\.'),
          onMatch: (_) => '.',
          onNonMatch: (_) => '',
        )
        .length;

    if (dotCount > 1) return oldValue;

    if (text == '-' || text == '-.' || text == '.') return newValue;

    final number = num.tryParse(text);
    if (number == null) return oldValue;

    return newValue;
  }
}

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
  final double width;

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
    this.width = 0,
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
    return Semantics(
      label: widget.field.label,
      hint: widget.field.hint,
      child: TextFormField(
        obscureText: widget.field.obscureText,
        controller: _controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        maxLines: widget.field.type == FieldType.textArea ? widget.field.maxLines : 1,
        style: widget.theme.inputStyle ??
            TextStyle(
              fontSize: RjResponsive.inputFontSize(widget.width),
              color: const Color(0xFF111827),
            ),
        keyboardType: widget.field.type == FieldType.textArea ? TextInputType.multiline : TextInputType.text,
        decoration: widget.theme.inputDecoration(
          label: widget.field.label,
          hint: widget.field.hint,
          errorText: widget.errorText,
          isFocused: _isFocused,
          suffixIcon: widget.readOnly ? Icon(Icons.lock_outline, size: RjResponsive.suffixIconSize(widget.width), color: const Color(0xFF9CA3AF)) : null,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class RjNumberField extends StatefulWidget {
  final FieldMeta field;
  final dynamic value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(num? value) onChanged;
  final double width;

  const RjNumberField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.errorText,
    this.width = 0,
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
    return Semantics(
      label: widget.field.label,
      hint: widget.field.hint,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          _NumberInputFormatter(),
        ],
        style: widget.theme.inputStyle ??
            TextStyle(
              fontSize: RjResponsive.inputFontSize(widget.width),
              color: const Color(0xFF111827),
            ),
        decoration: widget.theme.inputDecoration(
          label: widget.field.label,
          hint: widget.field.hint,
          errorText: widget.errorText,
          isFocused: _isFocused,
        ),
        onChanged: (v) => widget.onChanged(num.tryParse(v)),
      ),
    );
  }
}
