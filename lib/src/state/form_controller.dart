import 'package:flutter/foundation.dart';
import '../models/field_meta.dart';
import '../models/form_result.dart';

/// The state controller for [RjForm].
///
/// Manages form values, validation errors, and dirty state.
/// Extends [ChangeNotifier] so it integrates naturally with
/// [ListenableBuilder], [ValueListenableBuilder], or any
/// state management solution that supports [ChangeNotifier].
///
/// You can either:
/// - Let [RjForm] create and manage its own internal controller, or
/// - Create your own and pass it via [RjForm.controller] to read
///   values from outside the form.
///
/// Example with external controller:
/// ```dart
/// final _controller = FormController();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// // Read values on submit:
/// void _onSubmit(FormResult result) {
///   print(_controller.values);
/// }
/// ```
class FormController extends ChangeNotifier {
  Map<String, dynamic> _values = {};
  Map<String, String> _errors = {};

  /// Current form values — key is [FieldMeta.key], value is the field value.
  Map<String, dynamic> get values => Map.unmodifiable(_values);

  /// Current validation errors — key is [FieldMeta.key], value is error message.
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// True if the form has any values set.
  bool get isDirty => _values.isNotEmpty;

  // ─── Values ────────────────────────────────────────────────────────────────

  /// Set a single field value.
  void setValue(String key, dynamic value) {
    _values = {..._values, key: value};
    notifyListeners();
  }

  /// Replace all values at once (used for edit/pre-fill mode).
  void setAll(Map<String, dynamic> values) {
    _values = Map<String, dynamic>.from(values);
    notifyListeners();
  }

  /// Remove a single field's value.
  void removeValue(String key) {
    final updated = {..._values}..remove(key);
    _values = updated;
    notifyListeners();
  }

  /// Clear all values and errors — resets the form to empty.
  void clear() {
    _values = {};
    _errors = {};
    notifyListeners();
  }

  /// Updates a value and recursively clears all downstream dependent fields.
  ///
  /// Used internally for cascading dropdowns.
  void setValueAndClearDependents(
    String key,
    dynamic value,
    List<FieldMeta> fields,
  ) {
    _values = {..._values, key: value};
    _clearDependentsRecursively(key, fields, {});
    notifyListeners();
  }

  void _clearDependentsRecursively(
    String changedKey,
    List<FieldMeta> fields,
    Set<String> visited,
  ) {
    if (visited.contains(changedKey)) return;
    visited.add(changedKey);

    final dependents = fields.where(
      (f) => f.dependency?.dependsOn == changedKey,
    );

    for (final field in dependents) {
      _values = {..._values}..remove(field.key);
      _clearDependentsRecursively(field.key, fields, visited);
    }
  }

  // ─── Errors ────────────────────────────────────────────────────────────────

  /// Set a validation error for a field.
  void setError(String key, String message) {
    _errors = {..._errors, key: message};
    notifyListeners();
  }

  /// Clear the validation error for a field.
  void clearError(String key) {
    final updated = {..._errors}..remove(key);
    _errors = updated;
    notifyListeners();
  }

  /// Clear all validation errors.
  void clearErrors() {
    _errors = {};
    notifyListeners();
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  /// Validates all visible fields against their [FieldMeta] rules.
  ///
  /// Returns true if the form is valid. Populates [errors] if not.
  bool validate(List<FieldMeta> fields) {
    clearErrors();
    bool isValid = true;

    for (final field in fields) {
      // Skip hidden fields
      if (field.dependency != null &&
          !field.dependency!.isVisible(_values)) {
        continue;
      }

      final value = _values[field.key];

      // Required check
      if (field.required) {
        final isEmpty = value == null ||
            (value is String && value.trim().isEmpty) ||
            (value is List && value.isEmpty);

        if (isEmpty) {
          setError(field.key, '${field.label} is required');
          isValid = false;
          continue;
        }
      }

      // Custom validators
      for (final validator in field.validators) {
        final error = validator(value);
        if (error != null) {
          setError(field.key, error);
          isValid = false;
          break;
        }
      }
    }

    return isValid;
  }

  /// Returns the current state as a [FormResult].
  FormResult toResult() => FormResult(Map<String, dynamic>.from(_values));
}
