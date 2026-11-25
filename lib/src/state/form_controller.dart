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
///
/// ## Repeatable groups
///
/// Group values are stored as `List<Map<String, dynamic>>` under the group
/// `FieldMeta.key`. Each row map carries an internal `__rowId` (stripped from
/// the public [values] and [FormResult]) so row identity, error keys and widget
/// keys stay stable regardless of list position. Row-field errors are keyed
/// `'<groupKey>.<rowId>.<subKey>'` — see [RjErrorKey].
class FormController extends ChangeNotifier {
  Map<String, dynamic> _values = {};
  Map<String, String> _errors = {};

  static const String _rowIdKey = '__rowId';

  int _groupRowSeed = 0;
  int _groupVersion = 0;

  String _newRowId(String groupKey) => 'row_${groupKey}_${++_groupRowSeed}';

  static String _rowIdOf(Map row, int index) =>
      (row[_rowIdKey] as String?) ?? 'idx_$index';

  /// Resolves the stable row id for a row map, falling back to an index-based
  /// synthetic id when the row was supplied without one (e.g. via external
  /// [setAll] before normalization). Public so widgets can key rows.
  static String rowIdOf(dynamic row, int index) =>
      row is Map ? _rowIdOf(row, index) : 'idx_$index';

  /// Current form values — key is [FieldMeta.key], value is the field value.
  ///
  /// Returns an **unmodifiable deep copy**. Mutating the returned map (or any
  /// nested list/map) never corrupts internal state. Group row maps are
  /// returned without their internal `__rowId`.
  Map<String, dynamic> get values => Map.unmodifiable(_sanitizedValues());

  /// Current validation errors — key is [FieldMeta.key], value is error message.
  /// Group row errors use composite `'<groupKey>.<rowId>.<subKey>'` keys.
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// Raw internal value for a key. Intended for engine widgets only; the
  /// returned value is not copied and must not be mutated.
  dynamic rawValue(String key) => _values[key];

  /// Raw internal error for a key. Intended for engine widgets only.
  String? rawError(String key) => _errors[key];

  /// Raw internal state map. Intended for engine widgets only; must not be
  /// mutated.
  Map<String, dynamic> get rawState => _values;

  /// Shallow copies of the raw rows for a group key. Returns null when the key
  /// does not hold group rows.
  List<Map<String, dynamic>>? rawGroupRows(String groupKey) {
    final v = _values[groupKey];
    if (v is! List) return null;
    if (v.isEmpty) return <Map<String, dynamic>>[];
    if (v.first is! Map) return null;
    return List<Map<String, dynamic>>.from(
      v.map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }

  /// Builds the composite error key for a row field.
  String groupErrorKey(String groupKey, String rowId, String subKey) =>
      '$groupKey.$rowId.$subKey';

  /// Resolves the positional index of [rowId] within a group's rows.
  /// Returns -1 when the row does not exist.
  int groupIndexForId(String groupKey, String rowId) {
    final rows = _values[groupKey];
    if (rows is! List) return -1;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is Map && _rowIdOf(row, i) == rowId) return i;
    }
    return -1;
  }

  /// Incremented whenever a group's row structure or a row value changes.
  /// Widgets that display row positions derive freshness from this.
  int get groupVersion => _groupVersion;

  /// True if the form has any values set.
  ///
  /// Blank group rows that the engine seeds to satisfy `GroupConfig.minRows`
  /// do not count.
  bool get isDirty => _values.values.any((v) => !_isSeededBlankGroup(v));

  // ─── Values ────────────────────────────────────────────────────────────────

  /// Set a single field value.
  void setValue(String key, dynamic value) {
    _values = {..._values, key: value};
    notifyListeners();
  }

  /// Replace all values at once (used for edit/pre-fill mode).
  ///
  /// Group rows are given missing `__rowId`s lazily — call
  /// [recomputeAllDerivations] (as the [RjForm] `initialValues` path already
  /// does) or submit to normalize them. See [ensureGroupRows].
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

  /// Updates a value and computes derivations for non-cascading fields.
  ///
  /// Used internally for text, number, date, etc.
  void setValueWithDerivation(
    String key,
    dynamic value,
    List<FieldMeta> fields,
  ) {
    _values = {..._values, key: value};
    _recomputeRootFrom(key, fields);
    _afterRootValueChange(key, fields);
    notifyListeners();
  }

  /// Updates a value, clears downstream dependents, handles labels, and
  /// computes derivations in a single pass.
  ///
  /// [extraValues] is used for label shadowing — e.g.,
  /// `{'groupIdLabel': 'Dairy Cows'}` is stored alongside `groupId`.
  ///
  /// Used internally for cascading dropdowns.
  void setValueAndClearDependents(
    String key,
    dynamic value,
    List<FieldMeta> fields, {
    Map<String, dynamic> extraValues = const {},
  }) {
    _values = {..._values, key: value, ...extraValues};
    final working = Map.of(_values);
    _clearDependentsIn(
      state: working,
      changedKey: key,
      localFields: fields,
      visited: {},
    );
    _values = working;
    _recomputeRootFrom(key, fields);
    _afterRootValueChange(key, fields);
    notifyListeners();
  }

  // ─── Group rows ────────────────────────────────────────────────────────────

  /// Ensures a group holds at least `GroupConfig.minRows` rows, seeding blank
  /// rows and injecting missing `__rowId`s. Called internally on first render
  /// and again whenever the group's rows are wiped (e.g. by [clear] or
  /// [setAll]).
  ///
  /// Does not notify listeners. Returns true when the stored rows changed.
  bool ensureGroupRows(String groupKey, List<FieldMeta> fields) {
    final groupMeta = _groupMeta(fields, groupKey);
    if (groupMeta == null) return false;
    final minRows = groupMeta.groupConfig.minRows;
    final existing = _values[groupKey];
    var changed = existing is! List && minRows > 0;
    final rows = <Map<String, dynamic>>[];
    if (existing is List) {
      for (final e in existing) {
        if (e is Map) {
          rows.add(Map<String, dynamic>.from(e));
        } else {
          rows.add(<String, dynamic>{});
          changed = true;
        }
      }
    }
    while (rows.length < minRows) {
      rows.add({_rowIdKey: _newRowId(groupKey)});
      changed = true;
    }
    for (final row in rows) {
      if (!row.containsKey(_rowIdKey)) {
        row[_rowIdKey] = _newRowId(groupKey);
        changed = true;
      }
    }
    if (!changed) return false;
    _values = {..._values, groupKey: rows};
    _groupVersion++;
    return true;
  }

  /// Appends a new blank row to a group, respecting `GroupConfig.maxRows`.
  void addGroupRow(String groupKey, List<FieldMeta> fields) {
    final groupMeta = _groupMeta(fields, groupKey);
    final cfg = groupMeta?.groupConfig;
    final existing = _values[groupKey];
    final rows = existing is List
        ? List<Map<String, dynamic>>.from(
            existing.map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];
    if (cfg?.maxRows != null && rows.length >= cfg!.maxRows!) return;
    rows.add({_rowIdKey: _newRowId(groupKey)});
    _values = {..._values, groupKey: rows};
    _groupVersion++;
    // Roll-ups over the group (counts, grand totals) must see the new row.
    _recomputeRootFrom(groupKey, fields);
    notifyListeners();
  }

  /// Removes a row, respecting `GroupConfig.minRows`, and purges its errors.
  void removeGroupRow(String groupKey, String rowId, List<FieldMeta> fields) {
    final groupMeta = _groupMeta(fields, groupKey);
    final cfg = groupMeta?.groupConfig;
    final existing = _values[groupKey];
    if (existing is! List) return;
    final rows = List<Map<String, dynamic>>.from(
      existing.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final idx = groupIndexForId(groupKey, rowId);
    if (idx == -1) return;
    if (cfg != null && rows.length <= cfg.minRows) return;
    rows.removeAt(idx);
    _values = {..._values, groupKey: rows};
    final prefix = '$groupKey.$rowId.';
    final updated = Map<String, String>.from(_errors)
      ..removeWhere((k, _) => k.startsWith(prefix));
    _errors = updated;
    _groupVersion++;
    // Roll-ups over the group (e.g. grand totals) must drop the removed row.
    _recomputeRootFrom(groupKey, fields);
    notifyListeners();
  }

  /// Sets a single sub-field value inside a group row and recomputes row-scoped
  /// then root derivations (e.g. grand totals reading the group key).
  void setGroupRowValue(
    String groupKey,
    String rowId,
    String subKey,
    dynamic value,
    List<FieldMeta> fields,
  ) {
    if (!_mutateRowField(groupKey, rowId, subKey, value)) return;
    _groupVersion++;
    _afterGroupRowValueChange(groupKey, rowId, subKey, fields);
    notifyListeners();
  }

  /// Like [setGroupRowValue] but also clears dependents inside the row
  /// (cascading dropdowns) and accepts label-shadow [extraValues].
  void setGroupRowValueCascade(
    String groupKey,
    String rowId,
    String subKey,
    dynamic value,
    List<FieldMeta> fields, {
    Map<String, dynamic> extraValues = const {},
  }) {
    if (!_mutateRowField(groupKey, rowId, subKey, value, extraValues)) return;
    _groupVersion++;
    final groupMeta = _groupMeta(fields, groupKey);
    if (groupMeta != null) {
      final row = _rowMap(groupKey, rowId);
      if (row != null) {
        final working = Map.of(row);
        _clearDependentsIn(
          state: working,
          changedKey: subKey,
          localFields: groupMeta.groupFields ?? const [],
          visited: {},
        );
        _writeRowBack(groupKey, rowId, working);
      }
    }
    _afterGroupRowValueChange(groupKey, rowId, subKey, fields);
    notifyListeners();
  }

  // ─── Errors ────────────────────────────────────────────────────────────────

  /// Set a validation error for a field (or a composite group key).
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

  /// Clears errors on root derived fields that derive from [changedKey].
  void clearDerivedFieldErrors(String changedKey, List<FieldMeta> fields) {
    for (final field in fields) {
      if (field.type == FieldType.group) continue;
      if (field.derivation != null &&
          field.derivation!.derivesFrom.contains(changedKey)) {
        clearError(field.key);
      }
    }
  }

  /// Clears errors on row-scoped derived fields and the enclosing group's root
  /// derivations after an in-row field changed.
  void clearGroupDerivedFieldErrors(
    String groupKey,
    String rowId,
    String subKey,
    List<FieldMeta> fields,
  ) {
    final groupMeta = _groupMeta(fields, groupKey);
    if (groupMeta != null) {
      for (final sub in groupMeta.groupFields ?? const []) {
        if (sub.derivation != null &&
            sub.derivation!.derivesFrom.contains(subKey)) {
          clearError(groupErrorKey(groupKey, rowId, sub.key));
        }
      }
    }
    for (final field in fields) {
      if (field.type == FieldType.group) continue;
      if (field.derivation != null &&
          field.derivation!.derivesFrom.contains(groupKey)) {
        clearError(field.key);
      }
    }
  }

  // ─── Validation ────────────────────────────────────────────────────────────

  /// Validates all visible fields against their [FieldMeta] rules, recursing
  /// into group rows. Returns true if the form is valid. Populates [errors]
  /// (with composite keys for row fields) if not.
  bool validate(List<FieldMeta> fields) {
    clearErrors();
    _ensureRowIdsIn(fields);
    bool isValid = true;

    for (final field in fields) {
      if (field.type == FieldType.group) {
        if (!_validateGroup(field)) isValid = false;
        continue;
      }

      // Skip hidden fields
      if (field.dependency != null && !field.dependency!.isVisible(_values)) {
        continue;
      }

      if (!_validateSingle(field, _values[field.key], null)) {
        isValid = false;
      }
    }

    return isValid;
  }

  bool _validateGroup(FieldMeta group) {
    // Skip hidden groups, like any other field.
    if (group.dependency != null && !group.dependency!.isVisible(_values)) {
      return true;
    }
    var valid = true;
    final g = group.key;
    final rows = _values[g];
    final rowKeys = group.groupFields ?? const [];

    // Group-level rules. `required` means at least one row with a
    // user-entered (non-derived) value; a seeded blank row does not count.
    final filledRows = rows is List
        ? rows.where((e) => e is Map && !_isBlankRow(e, rowKeys)).length
        : 0;
    if (group.required && filledRows == 0) {
      setError(g, '${group.label} is required');
      valid = false;
    } else {
      final publicRows = _deepCopy(rows is List ? rows : const [],
          stripRowIds: true);
      for (final validator in group.validators) {
        final error = validator(publicRows);
        if (error != null) {
          setError(g, error);
          valid = false;
          break;
        }
      }
    }

    if (rows is List) {
      for (var i = 0; i < rows.length; i++) {
        final e = rows[i];
        if (e is! Map) continue;
        final row = Map<String, dynamic>.from(e);
        final rowId = _rowIdOf(row, i);
        final merged = {..._values, ...row};
        for (final sub in rowKeys) {
          if (sub.dependency != null && !sub.dependency!.isVisible(merged)) {
            continue;
          }
          if (!_validateSingle(sub, row[sub.key], '$g.$rowId.${sub.key}')) {
            valid = false;
          }
        }
      }
    }
    return valid;
  }

  bool _validateSingle(FieldMeta field, dynamic value, String? errorKey) {
    final key = errorKey ?? field.key;
    if (field.required) {
      final isEmpty = value == null ||
          (value is String && value.trim().isEmpty) ||
          (value is List && value.isEmpty);

      if (isEmpty) {
        setError(key, '${field.label} is required');
        return false;
      }
    }

    for (final validator in field.validators) {
      final error = validator(value);
      if (error != null) {
        setError(key, error);
        return false;
      }
    }
    return true;
  }

  void _ensureRowIdsIn(List<FieldMeta> fields) {
    for (final groupMeta in fields) {
      if (groupMeta.type != FieldType.group) continue;
      final v = _values[groupMeta.key];
      if (v is! List) continue;
      var changed = false;
      final rows = <Map<String, dynamic>>[];
      for (final e in v) {
        if (e is! Map) continue;
        final row = Map<String, dynamic>.from(e);
        if (!row.containsKey(_rowIdKey)) {
          row[_rowIdKey] = _newRowId(groupMeta.key);
          changed = true;
        }
        rows.add(row);
      }
      if (changed) _values = {..._values, groupMeta.key: rows};
    }
  }

  /// Returns the current state as a [FormResult].
  ///
  /// The map is a deep copy; internal `__rowId` keys are stripped from group
  /// rows.
  FormResult toResult() => FormResult(_sanitizedValues());

  // ─── Derivations & cascading ───────────────────────────────────────────────

  /// Recomputes all derived fields (root and per-row, with merged scope).
  /// Call after [setAll] to ensure consistency.
  void recomputeAllDerivations(List<FieldMeta> fields) {
    _ensureRowIdsIn(fields);
    var working = Map.of(_values);

    // Root derivations (single pass per field list order).
    for (final f in fields) {
      if (f.type == FieldType.group) continue;
      if (f.derivation != null) {
        working[f.key] = f.derivation!.compute(working);
      }
    }

    // Row derivations with merged {root, row} scope; row keys win.
    final dirtyGroups = <String>{};
    for (final groupMeta in fields) {
      if (groupMeta.type != FieldType.group) continue;
      final rowKeys = groupMeta.groupFields ?? const [];
      final rows = working[groupMeta.key];
      if (rows is! List) continue;
      final newRows = <Map<String, dynamic>>[];
      var touched = false;
      for (final e in rows) {
        final row = Map<String, dynamic>.from(e as Map);
        final merged = {...working, ...row};
        for (final sub in rowKeys) {
          if (sub.derivation != null) {
            final computed = sub.derivation!.compute(merged);
            if (!identical(computed, row[sub.key])) touched = true;
            row[sub.key] = computed;
            merged[sub.key] = computed;
          }
        }
        newRows.add(row);
      }
      if (touched) dirtyGroups.add(groupMeta.key);
      working = {...working, groupMeta.key: newRows};
    }

    // Root fields deriving from a group key (grand totals) — recomputed last.
    for (final g in dirtyGroups) {
      for (final f in fields) {
        if (f.type == FieldType.group) continue;
        if (f.derivation != null && f.derivation!.derivesFrom.contains(g)) {
          working[f.key] = f.derivation!.compute(working);
        }
      }
    }

    _values = working;
    _groupVersion++;
    notifyListeners();
  }

  void _recomputeRootFrom(String changedKey, List<FieldMeta> fields) {
    final working = Map.of(_values);
    _recomputeDerivationsIn(
      working: working,
      read: working,
      changedKey: changedKey,
      localFields: fields,
      visited: {},
    );
    _values = Map.of(working);
  }

  // After a ROOT field changed, recompute row-scoped derivations/dependents
  // across every group row (rows see root state via merged scope), then
  // recompute root derivations once more for affected groups.
  void _afterRootValueChange(String key, List<FieldMeta> fields) {
    final affected = <String>{};
    for (final groupMeta in fields) {
      if (groupMeta.type != FieldType.group) continue;
      final rowKeys = groupMeta.groupFields ?? const [];
      final rows = _values[groupMeta.key];
      if (rows is! List) continue;
      for (var i = 0; i < rows.length; i++) {
        final e = rows[i];
        if (e is! Map) continue;
        final original = Map<String, dynamic>.from(e);
        final working = Map.of(original);
        final merged = {..._values, ...original};
        _clearDependentsIn(
          state: working,
          changedKey: key,
          localFields: rowKeys,
          visited: {},
        );
        _recomputeDerivationsIn(
          working: working,
          read: merged,
          changedKey: key,
          localFields: rowKeys,
          visited: {},
        );
        if (!_shallowEq(working, original)) {
          _writeRowBack(groupMeta.key, _rowIdOf(original, i), working);
          affected.add(groupMeta.key);
        }
      }
    }
    for (final g in affected) {
      _recomputeRootFrom(g, fields);
    }
  }

  // After a ROW field changed, recompute row-scoped derivations, then root
  // derivations deriving from the group key (grand totals).
  void _afterGroupRowValueChange(
    String groupKey,
    String rowId,
    String subKey,
    List<FieldMeta> fields,
  ) {
    final groupMeta = _groupMeta(fields, groupKey);
    if (groupMeta != null) {
      final row = _rowMap(groupKey, rowId);
      if (row != null) {
        final working = Map.of(row);
        final merged = {..._values, ...row};
        _recomputeDerivationsIn(
          working: working,
          read: merged,
          changedKey: subKey,
          localFields: groupMeta.groupFields ?? const [],
          visited: {},
        );
        if (!_shallowEq(working, row)) {
          _writeRowBack(groupKey, rowId, working);
        }
      }
    }
    _recomputeRootFrom(groupKey, fields);
  }

  void _recomputeDerivationsIn({
    required Map<String, dynamic> working,
    required Map<String, dynamic> read,
    required String changedKey,
    required List<FieldMeta> localFields,
    required Set<String> visited,
  }) {
    if (visited.contains(changedKey)) return;
    visited.add(changedKey);

    for (final f in localFields) {
      if (f.derivation == null || visited.contains(f.key)) continue;
      if (!f.derivation!.derivesFrom.contains(changedKey)) continue;

      final computed = f.derivation!.compute(read);
      working[f.key] = computed;
      read[f.key] = computed;
      _recomputeDerivationsIn(
        working: working,
        read: read,
        changedKey: f.key,
        localFields: localFields,
        visited: visited,
      );
    }
  }

  void _clearDependentsIn({
    required Map<String, dynamic> state,
    required String changedKey,
    required List<FieldMeta> localFields,
    required Set<String> visited,
  }) {
    if (visited.contains(changedKey)) return;
    visited.add(changedKey);

    for (final f in localFields) {
      if (f.dependency?.dependsOn != changedKey) continue;
      if (visited.contains(f.key)) continue;
      state.remove(f.key);
      state.remove('${f.key}Label');
      _clearDependentsIn(
        state: state,
        changedKey: f.key,
        localFields: localFields,
        visited: visited,
      );
    }
  }

  // ─── Internals ─────────────────────────────────────────────────────────────

  FieldMeta? _groupMeta(List<FieldMeta> fields, String groupKey) {
    for (final f in fields) {
      if (f.key == groupKey && f.type == FieldType.group) return f;
    }
    return null;
  }

  void _writeRowBack(String groupKey, String rowId, Map<String, dynamic> rowMap) {
    final existing = _values[groupKey];
    if (existing is! List) return;
    final idx = groupIndexForId(groupKey, rowId);
    if (idx == -1) return;
    final rows = List<Map<String, dynamic>>.from(
      existing.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    rows[idx] = rowMap;
    _values = {..._values, groupKey: rows};
  }

  Map<String, dynamic>? _rowMap(String groupKey, String rowId) {
    final v = _values[groupKey];
    if (v is! List) return null;
    for (var i = 0; i < v.length; i++) {
      final e = v[i];
      if (e is Map && _rowIdOf(e, i) == rowId) {
        return Map<String, dynamic>.from(e);
      }
    }
    return null;
  }

  bool _mutateRowField(
    String groupKey,
    String rowId,
    String subKey,
    dynamic value, [
    Map<String, dynamic> extraValues = const {},
  ]) {
    final existing = _values[groupKey];
    if (existing is! List) return false;
    final idx = groupIndexForId(groupKey, rowId);
    if (idx == -1) return false;
    final rows = List<Map<String, dynamic>>.from(
      existing.map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final row = rows[idx];
    row[subKey] = value;
    row.addAll(extraValues);
    rows[idx] = row;
    _values = {..._values, groupKey: rows};
    return true;
  }

  static bool _isEmptyValue(dynamic v) =>
      v == null ||
      (v is String && v.trim().isEmpty) ||
      (v is Iterable && v.isEmpty) ||
      (v is Map && v.isEmpty);

  /// True when no non-derived sub-field of [row] holds a value.
  static bool _isBlankRow(Map row, List<FieldMeta> rowFields) {
    for (final sub in rowFields) {
      if (sub.derivation != null) continue;
      if (!_isEmptyValue(row[sub.key])) return false;
    }
    return true;
  }

  /// True when [v] is a group list made only of untouched seeded rows
  /// (maps holding nothing but `__rowId`).
  static bool _isSeededBlankGroup(dynamic v) =>
      v is List &&
      v.isNotEmpty &&
      v.every((e) => e is Map && e.length == 1 && e.containsKey(_rowIdKey));

  static bool _shallowEq(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  Map<String, dynamic> _sanitizedValues() =>
      Map<String, dynamic>.from(_deepCopy(_values, stripRowIds: true) as Map);

  static dynamic _deepCopy(dynamic value, {bool stripRowIds = false}) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        if (stripRowIds && k == _rowIdKey) return;
        out[k.toString()] = _deepCopy(v, stripRowIds: stripRowIds);
      });
      return out;
    }
    if (value is List) {
      return value.map((e) => _deepCopy(e, stripRowIds: stripRowIds)).toList();
    }
    return value;
  }
}