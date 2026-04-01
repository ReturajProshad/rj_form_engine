import 'package:flutter/widgets.dart';
import 'dropdown_item.dart';
import 'dropdown_source.dart';

enum FieldType {
  text,
  number,
  date,
  dropdown,
  image,
  textArea,
  custom,

  /// A horizontal draggable slider. Returns a [double].
  slider,

  /// A time picker (clock UI). Returns a [TimeOfDay].
  timePicker,

  /// A number stepper with + / - buttons. Returns an [int].
  spinner,

  /// A boolean on/off toggle switch. Returns a [bool].
  toggle,

  /// Pick exactly one option from a list. Returns the selected [id] string.
  radio,

  /// Select multiple options from a chip list. Returns [List<String>] of ids.
  chip,
}

typedef FieldValidator = String? Function(dynamic value);

typedef CustomFieldBuilder = Widget Function(
  BuildContext context,
  dynamic value,
  void Function(dynamic value) onChanged,
  String? errorText,
);

class FieldDependency {
  final String dependsOn;
  final bool Function(dynamic parentValue)? condition;
  const FieldDependency({required this.dependsOn, this.condition});

  bool isVisible(Map<String, dynamic> formState) {
    final parentValue = formState[dependsOn];
    if (condition == null) return parentValue != null;
    return condition!(parentValue);
  }
}

class FieldMeta {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final DropdownSource? dropdownSource;
  final List<FieldValidator> validators;
  final String? dependsOn;
  final FieldDependency? dependency;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool viewOnly;
  final String? hint;
  final int maxImages;
  final int maxImageSizeBytes;
  final CustomFieldBuilder? builder;
  final bool obscureText;
  final int maxLines;

  // ─── Slider ───────────────────────────────────────────────────────────────
  final double sliderMin;
  final double sliderMax;
  final int? sliderDivisions;
  final String Function(double)? sliderLabelBuilder;

  // ─── Spinner ──────────────────────────────────────────────────────────────
  final int spinnerMin;
  final int spinnerMax;
  final int spinnerStep;

  // ─── Radio / Chip ─────────────────────────────────────────────────────────
  /// Options for [FieldType.radio] and [FieldType.chip].
  final List<DropdownItem> options;

  const FieldMeta({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.dropdownSource,
    this.validators = const [],
    this.dependsOn,
    this.dependency,
    this.firstDate,
    this.lastDate,
    this.viewOnly = false,
    this.hint,
    this.maxImages = 1,
    this.maxImageSizeBytes = 2 * 1024 * 1024,
    this.builder,
    this.sliderMin = 0.0,
    this.sliderMax = 100.0,
    this.sliderDivisions,
    this.sliderLabelBuilder,
    this.spinnerMin = 0,
    this.spinnerMax = 999,
    this.spinnerStep = 1,
    this.options = const [],
    this.obscureText = false,
    this.maxLines = 1,
  });

  const FieldMeta.custom({
    required String key,
    required String label,
    required CustomFieldBuilder builder,
    bool required = false,
    List<FieldValidator> validators = const [],
    FieldDependency? dependency,
    bool viewOnly = false,
  }) : this(
          key: key,
          label: label,
          type: FieldType.custom,
          required: required,
          validators: validators,
          dependency: dependency,
          viewOnly: viewOnly,
          builder: builder,
        );

  FieldMeta copyWith({
    bool? viewOnly,
    bool? required,
    String? hint,
    DateTime? firstDate,
    DateTime? lastDate,
    bool? obscureText,
    int? maxLines,
  }) {
    return FieldMeta(
      key: key,
      label: label,
      type: type,
      required: required ?? this.required,
      dropdownSource: dropdownSource,
      validators: validators,
      dependsOn: dependsOn,
      dependency: dependency,
      firstDate: firstDate ?? this.firstDate,
      lastDate: lastDate ?? this.lastDate,
      viewOnly: viewOnly ?? this.viewOnly,
      hint: hint ?? this.hint,
      maxImages: maxImages,
      maxImageSizeBytes: maxImageSizeBytes,
      builder: builder,
      sliderMin: sliderMin,
      sliderMax: sliderMax,
      sliderDivisions: sliderDivisions,
      sliderLabelBuilder: sliderLabelBuilder,
      spinnerMin: spinnerMin,
      spinnerMax: spinnerMax,
      spinnerStep: spinnerStep,
      options: options,
      obscureText: obscureText ?? this.obscureText,
      maxLines: maxLines ?? this.maxLines,
    );
  }
}
