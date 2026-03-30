import 'package:flutter/material.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';

class RjDateField extends StatefulWidget {
  final FieldMeta field;
  final DateTime? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(DateTime value) onChanged;

  const RjDateField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.errorText,
  });

  @override
  State<RjDateField> createState() => _RjDateFieldState();
}

class _RjDateFieldState extends State<RjDateField> {
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
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(RjDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final formatted = _format(widget.value);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _format(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now,
      firstDate: widget.field.firstDate ?? DateTime(1900),
      lastDate: widget.field.lastDate ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.theme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _controller.text = _format(picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: true,
      onTap: _pickDate,
      style: widget.theme.inputStyle ??
          const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: widget.theme.inputDecoration(
        label: widget.field.label,
        hint: widget.field.hint ?? 'YYYY-MM-DD',
        errorText: widget.errorText,
        isFocused: _isFocused,
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          size: 18,
          color: widget.theme.primaryColor,
        ),
      ),
    );
  }
}
