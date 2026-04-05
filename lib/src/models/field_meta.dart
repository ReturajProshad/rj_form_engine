// =============================================================================
// STEP 1 — PATCH A: field_meta.dart
// Fix: Section key collision when label is not unique
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// BUG EXPLANATION — Section Key Collision
//
// BEFORE (broken):
//   factory FieldMeta.section({
//     String key = '',
//     required String label,
//   }) {
//     return FieldMeta(
//       key: key.isEmpty
//           ? 'section_${label.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}'
//           : key,
//       ...
//     );
//   }
//
// WHY IT'S A BUG:
//   If a developer has two sections with the same label (e.g. two sections
//   both called "Details"), they generate the same key: "section_details".
//   FormController uses keys as primary identifiers for values and errors.
//   Two fields sharing a key means one silently overwrites the other.
//   Additionally the generated key is never documented, so developers
//   don't know they need to provide unique labels to avoid collisions.
//
//   Worse: in debug mode there is NO assert to catch this. A production
//   app can ship with this bug silently.
//
// FIX:
//   1. Use a counter-based fallback so the key is always unique.
//   2. Add a debug-mode assert that fires when duplicate keys are detected
//      at the form level (in FormController.validate, see form_controller patch).
//   3. Warn via assert when key is empty — encourage explicit keys.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/widgets.dart';
import 'dropdown_item.dart';
import 'dropdown_source.dart';

// Internal counter for auto-generated section keys.
// Resets are not needed — keys are unique within a session.
int _sectionKeyCounter = 0;

enum FieldType {
  text,
  number,
  date,
  dropdown,
  image,
  textArea,
  custom,
  slider,
  timePicker,
  spinner,
  toggle,
  radio,
  chip,
  section,
}

typedef FieldValidator = String? Function(dynamic value);

// FIX D: CustomFieldBuilder now receives FieldMeta so the builder has access
// to label, hint, required, etc. without those being re-passed separately.
//
// BEFORE:
//   typedef CustomFieldBuilder = Widget Function(
//     BuildContext context,
//     dynamic value,
//     void Function(dynamic) onChanged,
//     String? errorText,
//   );
//
// MIGRATION:
//   BEFORE: builder: (context, value, onChanged, errorText) { ... }
//   AFTER:  builder: (context, field, value, onChanged, errorText) { ... }

typedef CustomFieldBuilder = Widget Function(
  BuildContext context,
  FieldMeta field,
  dynamic value,
  void Function(dynamic value) onChanged,
  String? errorText,
);

// ── Typed FieldConfig subclasses ────────────────────────────────────────────
//
// These are ADDITIVE. They live alongside FieldMeta's flat params.
// In a future v2, the flat params will be deprecated and FieldConfig
// will be the only way to configure field-specific behaviour.

sealed class FieldConfig {
  const FieldConfig();
}

/// Config for FieldType.slider
class SliderConfig extends FieldConfig {
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? labelBuilder;

  const SliderConfig({
    this.min = 0.0,
    this.max = 100.0,
    this.divisions,
    this.labelBuilder,
  }) : assert(min < max, 'SliderConfig: min must be less than max');
}

/// Config for FieldType.spinner
class SpinnerConfig extends FieldConfig {
  final int min;
  final int max;
  final int step;

  const SpinnerConfig({
    this.min = 0,
    this.max = 999,
    this.step = 1,
  }) : assert(min < max, 'SpinnerConfig: min must be less than max');
}

/// Config for FieldType.image
class ImageConfig extends FieldConfig {
  final int maxImages;
  final int maxImageSizeBytes;

  const ImageConfig({
    this.maxImages = 1,
    this.maxImageSizeBytes = 2 * 1024 * 1024,
  });
}

/// Config for FieldType.date
class DateConfig extends FieldConfig {
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? format; // e.g. 'dd/MM/yyyy'

  const DateConfig({this.firstDate, this.lastDate, this.format});
}

/// Config for FieldType.text / textArea
class TextConfig extends FieldConfig {
  final bool obscureText;
  final int maxLines;

  const TextConfig({this.obscureText = false, this.maxLines = 1});
}

/// Config for FieldType.timePicker
class TimeConfig extends FieldConfig {
  final String? format; // e.g. 'HH:mm'

  const TimeConfig({this.format});
}

// ─────────────────────────────────────────────────────────────────────────────

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
  final FieldDependency? dependency;
  final bool viewOnly;
  final String? hint;
  final CustomFieldBuilder? builder;

  // ── Typed config ──
  // When provided, these take precedence over the flat params below.
  final FieldConfig? config;

  // ── Flat params (backward compat — kept for now, will deprecate in v2) ──
  final DateTime? firstDate;
  final DateTime? lastDate;
  final int maxImages;
  final int maxImageSizeBytes;
  final bool obscureText;
  final int maxLines;
  final String? dateFormat;
  final String? timeFormat;
  final double sliderMin;
  final double sliderMax;
  final int? sliderDivisions;
  final String Function(double)? sliderLabelBuilder;
  final int spinnerMin;
  final int spinnerMax;
  final int spinnerStep;
  final List<DropdownItem> options; // for radio / chip

  const FieldMeta({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.dropdownSource,
    this.validators = const [],
    this.dependency,
    this.viewOnly = false,
    this.hint,
    this.builder,
    this.config,
    // flat compat params
    this.firstDate,
    this.lastDate,
    this.maxImages = 1,
    this.maxImageSizeBytes = 2 * 1024 * 1024,
    this.obscureText = false,
    this.maxLines = 1,
    this.dateFormat,
    this.timeFormat,
    this.sliderMin = 0.0,
    this.sliderMax = 100.0,
    this.sliderDivisions,
    this.sliderLabelBuilder,
    this.spinnerMin = 0,
    this.spinnerMax = 999,
    this.spinnerStep = 1,
    this.options = const [],
  })  : assert(
          sliderMin < sliderMax,
          'sliderMin ($sliderMin) must be less than sliderMax ($sliderMax)',
        ),
        assert(
          spinnerMin < spinnerMax,
          'spinnerMin ($spinnerMin) must be less than spinnerMax ($spinnerMax)',
        );

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

  // ─────────────────────────────────────────────────────────────────────────
  // FIXED: Section factory — guaranteed unique keys
  // ─────────────────────────────────────────────────────────────────────────
  factory FieldMeta.section({
    String? key,
    required String label,
  }) {
    assert(
      key != null && key.isNotEmpty,
      'FieldMeta.section: provide an explicit `key` for "$label".',
    );

    final resolvedKey = (key != null && key.isNotEmpty)
        ? key
        : 'section_${++_sectionKeyCounter}_${label.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

    return FieldMeta(
      key: resolvedKey,
      label: label,
      type: FieldType.section,
    );
  }

  // ── Typed config accessors ────────────────────────────────────────────────
  // These helpers allow widgets to read config cleanly, falling back to
  // the flat params when no typed config is provided.

  SliderConfig get sliderConfig => config is SliderConfig
      ? config as SliderConfig
      : SliderConfig(
          min: sliderMin,
          max: sliderMax,
          divisions: sliderDivisions,
          labelBuilder: sliderLabelBuilder,
        );

  SpinnerConfig get spinnerConfig => config is SpinnerConfig
      ? config as SpinnerConfig
      : SpinnerConfig(min: spinnerMin, max: spinnerMax, step: spinnerStep);

  ImageConfig get imageConfig => config is ImageConfig
      ? config as ImageConfig
      : ImageConfig(
          maxImages: maxImages,
          maxImageSizeBytes: maxImageSizeBytes,
        );

  DateConfig get dateConfig => config is DateConfig
      ? config as DateConfig
      : DateConfig(
          firstDate: firstDate,
          lastDate: lastDate,
          format: dateFormat,
        );

  TextConfig get textConfig => config is TextConfig
      ? config as TextConfig
      : TextConfig(obscureText: obscureText, maxLines: maxLines);

  TimeConfig get timeConfig => config is TimeConfig
      ? config as TimeConfig
      : TimeConfig(format: timeFormat);

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
      dependency: dependency,
      viewOnly: viewOnly ?? this.viewOnly,
      hint: hint ?? this.hint,
      builder: builder,
      config: config,
      firstDate: firstDate ?? this.firstDate,
      lastDate: lastDate ?? this.lastDate,
      maxImages: maxImages,
      maxImageSizeBytes: maxImageSizeBytes,
      obscureText: obscureText ?? this.obscureText,
      maxLines: maxLines ?? this.maxLines,
      dateFormat: dateFormat,
      timeFormat: timeFormat,
      sliderMin: sliderMin,
      sliderMax: sliderMax,
      sliderDivisions: sliderDivisions,
      sliderLabelBuilder: sliderLabelBuilder,
      spinnerMin: spinnerMin,
      spinnerMax: spinnerMax,
      spinnerStep: spinnerStep,
      options: options,
    );
  }
}
