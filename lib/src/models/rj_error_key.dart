/// Parsed representation of a composite error key produced by a
/// [FieldType.group] row field.
///
/// Row-field errors are stored under composite keys shaped
/// `'<groupKey>.<rowId>.<subKey>'`. This helper lets consumers translate a
/// raw error key back into its parts — for example inside a custom
/// `errorsSummaryBuilder`:
///
/// ```dart
/// errorsSummaryBuilder: (errors) {
///   final parsed = RjErrorKey.tryParse(errors.keys.first);
///   return parsed == null ? 'Fix the errors' : 'Fix ${parsed.groupKey} #${parsed.rowId}';
/// }
/// ```
class RjErrorKey {
  /// Key of the enclosing [FieldMeta.group].
  final String groupKey;

  /// Stable internal row id (never an index).
  final String rowId;

  /// Key of the field inside the row.
  final String subKey;

  const RjErrorKey(this.groupKey, this.rowId, this.subKey);

  /// Parses a composite key. Returns null for ordinary (non-group) keys such
  /// as `'email'`.
  static RjErrorKey? tryParse(String raw) {
    final firstDot = raw.indexOf('.');
    if (firstDot == -1) return null;
    final rest = raw.substring(firstDot + 1);
    final secondDot = rest.indexOf('.');
    if (secondDot == -1) return null;
    return RjErrorKey(
      raw.substring(0, firstDot),
      rest.substring(0, secondDot),
      rest.substring(secondDot + 1),
    );
  }

  @override
  String toString() => '$groupKey.$rowId.$subKey';
}