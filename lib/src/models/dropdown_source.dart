import 'dropdown_item.dart';

/// Defines how a dropdown field loads its items.
///
/// Use [DropdownSource.static] for a fixed list known at build time.
/// Use [DropdownSource.async] for items fetched from an API or database.
///
/// Both variants support an optional [parentValue] parameter for
/// cascading dropdowns — the parent field's current value is passed
/// automatically by the engine.
///
/// Example — static:
/// ```dart
/// DropdownSource.static([
///   DropdownItem(id: 'active', label: 'Active'),
///   DropdownItem(id: 'inactive', label: 'Inactive'),
/// ])
/// ```
///
/// Example — async with cascade:
/// ```dart
/// DropdownSource.async(
///   (parentValue) async => fetchCitiesByCountry(parentValue),
/// )
/// ```
abstract class DropdownSource {
  const DropdownSource._();

  /// A fixed list of items — no async call needed.
  factory DropdownSource.static(List<DropdownItem> items) =>
      _StaticDropdownSource(items);

  /// An async loader. Receives the parent field's value when this field
  /// depends on another field (cascading). Otherwise [parentValue] is null.
  factory DropdownSource.async(
    Future<List<DropdownItem>> Function([dynamic parentValue]) loader,
  ) =>
      _AsyncDropdownSource(loader);

  /// Resolves the items. Called internally by the engine.
  Future<List<DropdownItem>> resolve([dynamic parentValue]);
}

class _StaticDropdownSource extends DropdownSource {
  final List<DropdownItem> _items;
  const _StaticDropdownSource(this._items) : super._();

  @override
  Future<List<DropdownItem>> resolve([dynamic parentValue]) async => _items;
}

class _AsyncDropdownSource extends DropdownSource {
  final Future<List<DropdownItem>> Function([dynamic parentValue]) _loader;
  const _AsyncDropdownSource(this._loader) : super._();

  @override
  Future<List<DropdownItem>> resolve([dynamic parentValue]) =>
      _loader(parentValue);
}
