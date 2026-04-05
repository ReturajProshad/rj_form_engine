import 'package:flutter/material.dart';
import '../../models/dropdown_item.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';
import '../../utils/rj_responsive.dart';
import '../../utils/rj_time_utils.dart';

// ─── Shared label row helper ─────────────────────────────────────────────────

Widget _fieldLabel(String label, bool required, RjFormTheme theme, {double width = 0}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(
          label,
          style: theme.labelStyle ??
              TextStyle(
                fontSize: RjResponsive.labelFontSize(width),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
        ),
        if (required) Text(' *', style: TextStyle(color: theme.errorColor)),
      ],
    ),
  );
}

Widget _errorText(String? error, RjFormTheme theme, {double width = 0}) {
  if (error == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      error,
      style: theme.errorStyle ?? TextStyle(color: theme.errorColor, fontSize: RjResponsive.errorFontSize(width)),
    ),
  );
}

// ─── Slider ──────────────────────────────────────────────────────────────────

class RjSliderField extends StatelessWidget {
  final FieldMeta field;
  final double? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(double value) onChanged;
  final double width;

  const RjSliderField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
    this.width = 0,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? field.sliderMin;
    final label = field.sliderLabelBuilder != null
        ? field.sliderLabelBuilder!(current)
        : current.toStringAsFixed(
            field.sliderDivisions != null ? 0 : 1,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme, width: width),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: errorText != null ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    field.sliderMin.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: RjResponsive.sliderLabelFontSize(width),
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: RjResponsive.sliderBadgeFontSize(width),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    field.sliderMax.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: RjResponsive.sliderLabelFontSize(width),
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: theme.primaryColor,
                  thumbColor: theme.primaryColor,
                  inactiveTrackColor: theme.primaryColor.withValues(alpha: 0.2),
                  overlayColor: theme.primaryColor.withValues(alpha: 0.1),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: current.clamp(field.sliderMin, field.sliderMax),
                  min: field.sliderMin,
                  max: field.sliderMax,
                  divisions: field.sliderDivisions,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
        _errorText(errorText, theme, width: width),
      ],
    );
  }
}
// ─── Time Picker ─────────────────────────────────────────────────────────────
//
// CHANGE: StatelessWidget → StatefulWidget
// REASON: Needs to own and dispose a TextEditingController.
//         Without this the controller leaks on every rebuild.

class RjTimePickerField extends StatefulWidget {
  final FieldMeta field;
  final TimeOfDay? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(TimeOfDay value) onChanged;
  final double width;

  const RjTimePickerField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
    this.width = 0,
  });

  @override
  State<RjTimePickerField> createState() => _RjTimePickerFieldState();
}

class _RjTimePickerFieldState extends State<RjTimePickerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Create ONCE. Never recreate in build().
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(RjTimePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync text when the parent passes a new value (e.g. pre-fill or reset).
    final formatted = _format(widget.value);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
  }

  @override
  void dispose() {
    // FIXED: Controller is now properly disposed.
    _controller.dispose();
    super.dispose();
  }

  String _format(TimeOfDay? t) {
    if (t == null) return '';
    final format = widget.field.timeFormat;
    if (format != null) return RjTimeUtils.format(t, format: format);
    return RjTimeUtils.format(t);
  }

  Future<void> _pick() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: widget.value ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: widget.theme.primaryColor,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _controller.text = _format(picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: _controller,
      onTap: _pick,
      style: widget.theme.inputStyle ??
          TextStyle(
            fontSize: RjResponsive.inputFontSize(widget.width),
            color: const Color(0xFF111827),
          ),
      decoration: widget.theme.inputDecoration(
        label: widget.field.label,
        hint: widget.field.hint ?? 'Select time',
        errorText: widget.errorText,
        suffixIcon: Icon(
          Icons.access_time_rounded,
          size: RjResponsive.suffixIconSize(widget.width),
          color: widget.theme.primaryColor,
        ),
      ),
    );
  }
}

// NOTE: RjDateField already uses StatefulWidget correctly (see date_field.dart).
// Its _controller is created in initState and disposed in dispose(). No fix needed.
// The only oversight in date_field.dart is that didUpdateWidget updates
// _controller.text correctly — that is already implemented. ✓

// ─── Spinner (Number Stepper) ─────────────────────────────────────────────────

class RjSpinnerField extends StatelessWidget {
  final FieldMeta field;
  final int? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(int value) onChanged;
  final double width;

  const RjSpinnerField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
    this.width = 0,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? field.spinnerMin;
    final canDecrement = current > field.spinnerMin;
    final canIncrement = current < field.spinnerMax;
    final btnSize = RjResponsive.spinnerButtonSize(width);
    final iconSize = RjResponsive.spinnerIconSize(width);
    final valueFontSize = RjResponsive.spinnerValueFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme, width: width),
        Container(
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: errorText != null ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: Row(
            children: [
              // Decrement button
              _SpinnerButton(
                icon: Icons.remove,
                enabled: canDecrement,
                primaryColor: theme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: theme.borderRadius.topLeft,
                  bottomLeft: theme.borderRadius.bottomLeft,
                ),
                onTap: canDecrement ? () => onChanged(current - field.spinnerStep) : null,
                buttonSize: btnSize,
                iconSize: iconSize,
              ),

              // Value display
              Expanded(
                child: Center(
                  child: Text(
                    '$current',
                    style: theme.inputStyle ??
                        TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                  ),
                ),
              ),

              // Increment button
              _SpinnerButton(
                icon: Icons.add,
                enabled: canIncrement,
                primaryColor: theme.primaryColor,
                borderRadius: BorderRadius.only(
                  topRight: theme.borderRadius.topRight,
                  bottomRight: theme.borderRadius.bottomRight,
                ),
                onTap: canIncrement ? () => onChanged(current + field.spinnerStep) : null,
                buttonSize: btnSize,
                iconSize: iconSize,
              ),
            ],
          ),
        ),
        _errorText(errorText, theme, width: width),
      ],
    );
  }
}

class _SpinnerButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color primaryColor;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double buttonSize;
  final double iconSize;

  const _SpinnerButton({
    required this.icon,
    required this.enabled,
    required this.primaryColor,
    required this.borderRadius,
    required this.onTap,
    this.buttonSize = 52,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? primaryColor.withValues(alpha: 0.08) : Colors.grey.shade100,
            borderRadius: borderRadius,
          ),
          child: Icon(
            icon,
            color: enabled ? primaryColor : Colors.grey.shade400,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

// ─── Toggle ───────────────────────────────────────────────────────────────────

class RjToggleField extends StatelessWidget {
  final FieldMeta field;
  final bool? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(bool value) onChanged;
  final double width;

  const RjToggleField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
    this.width = 0,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? false;
    final labelFontSize = RjResponsive.toggleLabelFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: errorText != null ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          field.label,
                          style: theme.labelStyle ??
                              TextStyle(
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF374151),
                              ),
                        ),
                        if (field.required) Text(' *', style: TextStyle(color: theme.errorColor)),
                      ],
                    ),
                    if (field.hint != null)
                      Text(
                        field.hint!,
                        style: theme.hintStyle ??
                            TextStyle(
                              fontSize: RjResponsive.errorFontSize(width),
                              color: const Color(0xFF9CA3AF),
                            ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: current,
                onChanged: onChanged,
                activeThumbColor: theme.primaryColor,
              ),
            ],
          ),
        ),
        _errorText(errorText, theme, width: width),
      ],
    );
  }
}

// ─── Radio ───────────────────────────────────────────────────────────────────

class RjRadioField extends StatelessWidget {
  final FieldMeta field;
  final String? value;
  final String? errorText;
  final RjFormTheme theme;
  final List<DropdownItem> options;
  final void Function(String value) onChanged;
  final double width;

  const RjRadioField({
    super.key,
    required this.field,
    required this.options,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
    this.width = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme, width: width),
        Container(
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: errorText != null ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: RadioGroup<String>(
            groupValue: value,
            onChanged: (String? v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              children: options.map((option) {
                final selected = value == option.id;
                return ListTile(
                  leading: Radio<String>(
                    value: option.id,
                    activeColor: theme.primaryColor,
                  ),
                  title: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: RjResponsive.radioOptionFontSize(width),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? theme.primaryColor : const Color(0xFF374151),
                    ),
                  ),
                  subtitle: option.sublabel != null ? Text(option.sublabel!, style: TextStyle(fontSize: RjResponsive.errorFontSize(width))) : null,
                  dense: true,
                  onTap: () => onChanged(option.id),
                );
              }).toList(),
            ),
          ),
        ),
        _errorText(errorText, theme, width: width),
      ],
    );
  }
}

// ─── Chip (Multi-select) ──────────────────────────────────────────────────────

class RjChipField extends StatelessWidget {
  final FieldMeta field;
  final List<String> value;
  final String? errorText;
  final RjFormTheme theme;
  final List<DropdownItem> options;
  final void Function(List<String> value) onChanged;
  final double width;

  const RjChipField({
    super.key,
    required this.field,
    required this.options,
    required this.onChanged,
    required this.theme,
    this.value = const [],
    this.errorText,
    this.width = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme, width: width),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: errorText != null ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: Wrap(
            spacing: RjResponsive.chipSpacing(width),
            runSpacing: RjResponsive.chipSpacing(width),
            children: options.map((option) {
              final selected = value.contains(option.id);
              return FilterChip(
                label: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: RjResponsive.chipLabelFontSize(width),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  final updated = List<String>.from(value);
                  if (selected) {
                    updated.remove(option.id);
                  } else {
                    updated.add(option.id);
                  }
                  onChanged(updated);
                },
                selectedColor: theme.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: theme.fieldFillColor,
                side: BorderSide(
                  color: selected ? theme.primaryColor : theme.borderColor,
                ),
                showCheckmark: true,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }).toList(),
          ),
        ),
        _errorText(errorText, theme, width: width),
      ],
    );
  }
}
