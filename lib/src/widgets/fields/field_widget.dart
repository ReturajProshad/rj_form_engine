import 'package:flutter/material.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';
import 'date_field.dart';
import 'dropdown_field.dart';
import 'extra_fields.dart';
import 'image_field.dart';
import 'searchable_dropdown_field.dart';
import 'text_fields.dart';

/// Shared entry point that renders the widget for a single non-group
/// [FieldMeta] (text, number, dropdown, image, custom, …).
///
/// Both the top-level form ([FieldType] roots) and repeatable group rows use
/// this function. Callers inject ready-bound callbacks so the same widget tree
/// supports root keys and composite `'<groupKey>.<rowId>.<subKey>'` keys.
Widget buildFieldWidget({
  required BuildContext context,
  required FieldMeta field,
  required dynamic value,
  required String? error,
  required RjFormTheme theme,
  required double width,
  required dynamic parentValue,
  required void Function(dynamic value) onChange,
  required void Function(String? value, {String? label}) onCascadeChange,
  required void Function(String error) onImageValidationError,
}) {
  switch (field.type) {
    case FieldType.text:
      return RjTextField(
        field: field,
        value: value,
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.textArea:
      return RjTextField(
        field: field,
        value: value,
        errorText: error,
        theme: theme,
        maxLines: 4,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.number:
      return RjNumberField(
        field: field,
        value: value,
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.date:
      return RjDateField(
        field: field,
        value: value is DateTime ? value : null,
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.dropdown:
      return RjDropdownField(
        field: field,
        value: value?.toString(),
        parentValue: parentValue,
        errorText: error,
        theme: theme,
        onChanged: (v, {label}) => onCascadeChange(v, label: label),
        width: width,
      );

    case FieldType.searchableDropdown:
      return RjSearchableDropdownField(
        field: field,
        value: value?.toString(),
        parentValue: parentValue,
        errorText: error,
        theme: theme,
        onChanged: (v, {label}) => onCascadeChange(v, label: label),
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
        onChanged: (v) => onChange(v),
        onValidationError: onImageValidationError,
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
        (v) => onChange(v),
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
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.timePicker:
      return RjTimePickerField(
        field: field,
        value: value is TimeOfDay ? value : null,
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.spinner:
      return RjSpinnerField(
        field: field,
        value: value is int ? value : (value is num ? value.toInt() : null),
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.toggle:
      return RjToggleField(
        field: field,
        value: value is bool ? value : null,
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.radio:
      return RjRadioField(
        field: field,
        options: field.options,
        value: value?.toString(),
        errorText: error,
        theme: theme,
        onChanged: (v) => onChange(v),
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
        onChanged: (v) => onChange(v),
        width: width,
      );

    case FieldType.section:
      return const SizedBox.shrink();

    case FieldType.group:
      return Text(
        'Group fields must be rendered with RjGroupField (key: ${field.key})',
        style: TextStyle(color: theme.errorColor),
      );
  }
}