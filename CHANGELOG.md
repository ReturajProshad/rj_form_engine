## 1.0.0

> Stable release — typed factory constructors, responsive grid layout, enhanced DX, and zero breaking changes.

### Added

#### Typed Factory Constructors

- **13 factory constructors** on `FieldMeta`: `.text()`, `.number()`, `.textArea()`, `.date()`, `.dropdown()`, `.image()`, `.slider()`, `.spinner()`, `.timePicker()`, `.toggle()`, `.radio()`, `.chip()`, `.custom()`
- Each factory surfaces **only the params relevant to that field type** — no more `spinnerMin` on a text field
- `FieldMeta.custom()` enhanced — now accepts `hint`, `derivation`, `showLabel`, `labelConfig`
- Old `FieldMeta(key: ..., type: ..., ...)` constructor is **unchanged** — zero breaking changes

```dart
// Before
FieldMeta(key: 'email', label: 'Email', type: FieldType.text, required: true)

// After
FieldMeta.text(key: 'email', label: 'Email', required: true)
```

#### Responsive Grid Layout

- **`RjSpan` enum** — `full`, `half`, `third`, `quarter` for declaring field widths
- **`RjLayout` class** — configurable per-field layout with `md` (tablet) and optional `lg` (desktop)
- **Row-packing grid engine** — consecutive fields auto-group into `IntrinsicHeight` rows based on their span
- **Mobile-first** — phone (below 768px) always stacks full-width automatically; no config needed
- **Section-aware** — sections flush the current row and start fresh
- `RjResponsive.resolveSpan()` — resolves the effective column count from layout + screen width
- `RjLayout? layout` property on all factory constructors and `copyWith`

```dart
FieldMeta.text(
  key: 'email',
  label: 'Email',
  required: true,
  layout: const RjLayout(md: RjSpan.half), // side-by-side on tablet+
)
```

#### Other

- `hint` parameter added to `FieldMeta.radio()` and `FieldMeta.chip()` factories

### Changed

- Version bumped to **1.0.0** — stable API surface with all core features production-ready

### Documentation

- README fully rewritten: all examples use typed factory constructors
- New "Responsive Grid" section with `RjSpan`/`RjLayout` API docs
- Updated Limitations — multi-column grid is now natively supported
- Updated Roadmap — grid layout and typed factories marked complete

---

## 0.3.0

> Auto-derivation release — computed fields, label shadowing, chained derivations, and label customization.

### Added

- `FieldDerivation` class — declare that a field's value is auto-computed from other fields via a pure `compute` function
- `FieldMeta.derivation` property — attach a derivation to any field type
- `FormController.setValueWithDerivation()` — updates a value and recalculates all affected derived fields
- `FormController.setValueAndClearDependents()` — now accepts `extraValues` for label shadowing (e.g., `{'groupIdLabel': 'Dairy Cows'}`)
- `FormController.recomputeAllDerivations()` — recalculates all derived fields after `setAll()` (for edit mode)
- Label shadowing — dropdown labels are automatically stored alongside IDs (e.g., `groupId` + `groupIdLabel`) so `compute` functions have synchronous access to human-readable text
- Chained derivations — if field A derives B and B derives C, changing A updates the entire chain in one pass
- Derived fields are automatically read-only (`AbsorbPointer`) — users cannot manually edit computed values
- Derived field errors are automatically cleared when a source field changes
- `RjDropdownField.onChanged` now passes the selected item's label alongside the ID

### Examples

```dart
// Simple: default_value × 2 → derived_from_default
FieldMeta(
  key: 'derived_from_default',
  label: 'Doubled Value',
  type: FieldType.number,
  derivation: FieldDerivation(
    derivesFrom: ['default_value'],
    compute: (state) {
      final val = (state['default_value'] as num?)?.toDouble();
      return val != null ? val * 2 : null;
    },
  ),
)

// Multi-source: price × quantity → total
FieldDerivation(
  derivesFrom: ['price', 'quantity'],
  compute: (state) {
    final price = (state['price'] as num?)?.toDouble() ?? 0;
    final qty   = (state['quantity'] as num?)?.toDouble() ?? 0;
    return price * qty;
  },
)

// Label shadowing: combine dropdown labels into a tag
FieldDerivation(
  derivesFrom: ['category', 'item'],
  compute: (state) {
    final cat  = state['categoryLabel'] ?? '';
    final item = state['itemLabel'] ?? '';
  return [cat, item].where((p) => p.isNotEmpty).join(' - ');
})
```

### Added (Label Customization)

- `RjLabel` sealed class — customize field labels with `RjLabelText` (styled text) or `RjLabelCustom` (any widget)
- `FieldMeta.showLabel` (default `true`) — set to `false` to hide the field label entirely
- `FieldMeta.labelConfig` — when set with `showLabel: true`, overrides the default label with a custom `RjLabel` widget rendered above the field
- `RjFormTheme.inputDecoration()` — `label` parameter is now nullable, allowing label suppression at the decoration level

### Examples

```dart
// Hide the label entirely
FieldMeta(
  key: 'no_label',
  label: 'Hidden Label',
  type: FieldType.text,
  showLabel: false,
)

// Styled text label
FieldMeta(
  key: 'styled',
  label: 'Default',
  type: FieldType.text,
  labelConfig: const RjLabelText(
    text: 'Bold Blue Label',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
  ),
)

// Custom widget label
FieldMeta(
  key: 'custom',
  label: 'Default',
  type: FieldType.number,
  labelConfig: RjLabelCustom((context) => Row(
    children: [Icon(Icons.star), Text('Custom Label')],
  )),
)
```

---

## 0.2.1

- Added toggle obscure functionality to show/hide text in password fields.

---

## 0.2.0

> Refactor release — improved API consistency, performance, and type safety.

### Added

- Typed `FieldConfig` subclasses: `SliderConfig`, `SpinnerConfig`, `ImageConfig`, `DateConfig`, `TextConfig`, `TimeConfig`
- `FieldMeta.config` property for typed field configuration (takes precedence over flat params)
- Typed config accessors on `FieldMeta`: `sliderConfig`, `spinnerConfig`, `imageConfig`, `dateConfig`, `textConfig`, `timeConfig`
- `errorsSummaryBuilder` callback on `RjForm` for custom error summary messages
- `onSuccess` callback on `RjForm` — fires after `onSubmit` completes successfully
- `autoClearOnSubmit` option on `RjForm` to automatically reset form after submission
- `autoDismissKeyboard` option on `RjForm` (default: `true`)
- `FieldMeta.copyWith()` method for creating modified field copies
- `Semantics` labels on all field widgets for improved accessibility
- `RjTimeUtils` utility class for custom date/time formatting

### Changed

- `CustomFieldBuilder` signature now includes the full `FieldMeta` as the second parameter
- `DropdownSource.async` loader now receives `parentValue` as a named parameter: `({String? parentValue})`
- `FieldMeta.section` factory now requires an explicit `key` parameter to prevent key collisions
- Per-field rebuild optimization — `_FieldBuilder` only rebuilds when its own value, error, or parent value changes
- Dropdown "waiting for parent" state now uses `AbsorbPointer` + `Opacity` instead of deprecated `initialValue`
- `RjFormTheme` uses `withValues(alpha:)` instead of deprecated `withOpacity()`

### Fixed

- Section key collision when multiple sections share the same label
- Improved Dropdown handling to align with controlled form patterns
- `TextEditingController` memory leak in `RjTimePickerField`
- Dropdown assertion crash when pre-filled value is not in the loaded items list
- Form state sync when `FieldMeta` changes at runtime via `didUpdateWidget`

### Breaking Changes

- `CustomFieldBuilder` signature changed: added `FieldMeta field` as the second parameter. Update custom field builders from `(context, value, onChanged, errorText)` to `(context, field, value, onChanged, errorText)`.
- `FieldMeta.section` now requires an explicit `key` parameter. Previously auto-generated keys from labels could collide.
- `DropdownSource.async` loader signature changed: `parentValue` is now a named parameter. Update from `(parentValue) async => ...` to `({parentValue}) async => ...`.

---

## 0.1.0

> Initial public release.

### Added

- 13 field types: `text`, `number`, `date`, `dropdown`, `textArea`, `image`, `slider`, `timePicker`, `spinner`, `toggle`, `radio`, `chip`, `custom`
- `FieldMeta` schema-driven field definition with 20+ configuration options
- `RjForm` widget — renders fields from a `List<FieldMeta>` schema
- `FormController` (`ChangeNotifier`) for external form state management
- `DropdownSource` union type — static or async dropdown item loading
- Cascading dropdowns with auto-reload and auto-clear on parent change
- `FieldDependency` for conditional field visibility with custom condition predicates
- 25+ built-in validators via `RjValidators`: email, phone, URL, password rules, date ranges, length bounds, regex patterns, and more
- `RjFormTheme` for full visual customization of all field styles
- Pre-fill support via `initialValues` for edit and clone modes
- View-only (read-only) mode via `viewOnly` flag
- `onChanged` callback for real-time field change tracking
- Error summary display at the top of the form (`showErrorsSummary`)
- Custom date/time format strings (`dateFormat`, `timeFormat`)
- `FieldMeta.custom` for embedding any custom widget via a builder function
- `FieldMeta.section` for visual form section dividers
- Keyboard dismissal via tap outside fields
- Minimal dependencies: only `flutter` SDK + `image_picker`
- State-management agnostic — works with Provider, Riverpod, Bloc, GetX, or nothing
