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
