/// Represents a single item in a dropdown field.
class DropdownItem {
  /// The unique identifier stored in the form state.
  final String id;

  /// The label displayed in the dropdown UI.
  final String label;

  /// Optional secondary label (e.g. for bilingual apps).
  final String? sublabel;

  /// Optional extra data you want to carry alongside the item.
  final Map<String, dynamic>? metadata;

  const DropdownItem({
    required this.id,
    required this.label,
    this.sublabel,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DropdownItem(id: $id, label: $label)';
}
