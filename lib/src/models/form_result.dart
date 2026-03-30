/// The result object passed to [RjForm.onSubmit].
///
/// Contains the raw form values as a [Map<String, dynamic>].
/// Image fields contain a [List<String>] of file paths.
/// Dropdown fields contain the selected item's [id] string.
/// Date fields contain a [DateTime].
class FormResult {
  /// The raw key-value map of all form field values.
  final Map<String, dynamic> values;

  const FormResult(this.values);

  /// Retrieve a typed value by key.
  T? get<T>(String key) {
    final value = values[key];
    if (value is T) return value;
    return null;
  }

  /// Returns true if all values are null or empty.
  bool get isEmpty => values.isEmpty;

  @override
  String toString() => 'FormResult($values)';
}
