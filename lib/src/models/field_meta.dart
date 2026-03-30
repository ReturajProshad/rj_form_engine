import 'package:flutter/widgets.dart';
import 'dropdown_source.dart';

enum FieldType { text, number, date, dropdown, image, textArea, custom }

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
    );
  }
}
