import 'package:flutter/material.dart';
import '../../models/dropdown_item.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';

// ─── Shared label row helper ─────────────────────────────────────────────────

Widget _fieldLabel(String label, bool required, RjFormTheme theme) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Text(
          label,
          style: theme.labelStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
        ),
        if (required)
          Text(' *', style: TextStyle(color: theme.errorColor)),
      ],
    ),
  );
}

Widget _errorText(String? error, RjFormTheme theme) {
  if (error == null) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      error,
      style: theme.errorStyle ??
          TextStyle(color: theme.errorColor, fontSize: 12),
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

  const RjSliderField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
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
        _fieldLabel(field.label, field.required, theme),
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
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    field.sliderMax.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: theme.primaryColor,
                  thumbColor: theme.primaryColor,
                  inactiveTrackColor: theme.primaryColor.withOpacity(0.2),
                  overlayColor: theme.primaryColor.withOpacity(0.1),
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
        _errorText(errorText, theme),
      ],
    );
  }
}

// ─── Time Picker ─────────────────────────────────────────────────────────────

class RjTimePickerField extends StatelessWidget {
  final FieldMeta field;
  final TimeOfDay? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(TimeOfDay value) onChanged;

  const RjTimePickerField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
  });

  String _format(TimeOfDay? t) {
    if (t == null) return '';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: theme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: _format(value)),
      onTap: () => _pick(context),
      style: theme.inputStyle ??
          const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: theme.inputDecoration(
        label: field.label,
        hint: field.hint ?? 'Select time',
        errorText: errorText,
        suffixIcon: Icon(
          Icons.access_time_rounded,
          size: 18,
          color: theme.primaryColor,
        ),
      ),
    );
  }
}

// ─── Spinner (Number Stepper) ─────────────────────────────────────────────────

class RjSpinnerField extends StatelessWidget {
  final FieldMeta field;
  final int? value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(int value) onChanged;

  const RjSpinnerField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? field.spinnerMin;
    final canDecrement = current > field.spinnerMin;
    final canIncrement = current < field.spinnerMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme),
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
                onTap: canDecrement
                    ? () => onChanged(current - field.spinnerStep)
                    : null,
              ),

              // Value display
              Expanded(
                child: Center(
                  child: Text(
                    '$current',
                    style: theme.inputStyle ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
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
                onTap: canIncrement
                    ? () => onChanged(current + field.spinnerStep)
                    : null,
              ),
            ],
          ),
        ),
        _errorText(errorText, theme),
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

  const _SpinnerButton({
    required this.icon,
    required this.enabled,
    required this.primaryColor,
    required this.borderRadius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled
              ? primaryColor.withOpacity(0.08)
              : Colors.grey.shade100,
          borderRadius: borderRadius,
        ),
        child: Icon(
          icon,
          color: enabled ? primaryColor : Colors.grey.shade400,
          size: 20,
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

  const RjToggleField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final current = value ?? false;

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
                              const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                        ),
                        if (field.required)
                          Text(' *', style: TextStyle(color: theme.errorColor)),
                      ],
                    ),
                    if (field.hint != null)
                      Text(
                        field.hint!,
                        style: theme.hintStyle ??
                            const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: current,
                onChanged: onChanged,
                activeColor: theme.primaryColor,
              ),
            ],
          ),
        ),
        _errorText(errorText, theme),
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

  const RjRadioField({
    super.key,
    required this.field,
    required this.options,
    required this.onChanged,
    required this.theme,
    this.value,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme),
        Container(
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: errorText != null ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: Column(
            children: options.map((option) {
              final selected = value == option.id;
              return RadioListTile<String>(
                value: option.id,
                groupValue: value,
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? theme.primaryColor
                        : const Color(0xFF374151),
                  ),
                ),
                subtitle: option.sublabel != null
                    ? Text(option.sublabel!, style: const TextStyle(fontSize: 12))
                    : null,
                activeColor: theme.primaryColor,
                dense: true,
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              );
            }).toList(),
          ),
        ),
        _errorText(errorText, theme),
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

  const RjChipField({
    super.key,
    required this.field,
    required this.options,
    required this.onChanged,
    required this.theme,
    this.value = const [],
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(field.label, field.required, theme),
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
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = value.contains(option.id);
              return FilterChip(
                label: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
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
                  color:
                      selected ? theme.primaryColor : theme.borderColor,
                ),
                showCheckmark: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              );
            }).toList(),
          ),
        ),
        _errorText(errorText, theme),
      ],
    );
  }
}
