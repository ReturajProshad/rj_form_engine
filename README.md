# rj_form_engine

**A schema-driven form engine for Flutter.**

Build 100 forms from pure configuration. Zero external dependencies. Any state management.

[![pub.dev](https://img.shields.io/pub/v/rj_form_engine.svg)](https://pub.dev/packages/rj_form_engine)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why rj_form_engine?

Building forms in Flutter is repetitive. Every screen has the same patterns — text fields, dropdowns, date pickers, image uploads — all wired up by hand, validated by hand, and state-managed by hand.

`rj_form_engine` replaces all of that with a **schema**. You define what your form looks like. The engine renders it, validates it, and gives you the data.

```dart
RjForm(
  fields: [
    FieldMeta(key: 'name',    label: 'Full Name',     type: FieldType.text,     required: true),
    FieldMeta(key: 'dob',     label: 'Date of Birth', type: FieldType.date),
    FieldMeta(key: 'country', label: 'Country',       type: FieldType.dropdown,
      dropdownSource: DropdownSource.async(fetchCountries),
    ),
    FieldMeta(key: 'city',    label: 'City',          type: FieldType.dropdown,
      dropdownSource: DropdownSource.async(fetchCities),
      dependsOn: 'country',                           // cascades automatically
      dependency: FieldDependency(dependsOn: 'country'),
    ),
  ],
  onSubmit: (result) async {
    print(result.values); // {'name': 'John', 'dob': DateTime(...), ...}
  },
)
```

---

## Features

- **6 field types** — text, number, date, dropdown, image upload, textarea
- **Custom fields** — inject any widget via `FieldMeta.custom`
- **Cascading dropdowns** — parent/child dependency with auto-reload and auto-clear
- **Async dropdown loading** — load items from APIs, databases, or caches
- **Static dropdowns** — pass a fixed list when no async call is needed
- **Built-in validation** — required check + custom validator functions per field
- **Conditional visibility** — show/hide fields based on other field values
- **View / edit modes** — render read-only with a single flag
- **Pre-fill values** — for edit or clone mode
- **External controller** — read form state from outside the widget
- **Themeable** — one `RjFormTheme` controls all field styles
- **Zero dependencies** — only `flutter` SDK + `image_picker`

---

## Installation

```yaml
dependencies:
  rj_form_engine: ^0.0.1
```

```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:rj_form_engine/rj_form_engine.dart';

RjForm(
  fields: [
    FieldMeta(
      key: 'email',
      label: 'Email Address',
      type: FieldType.text,
      required: true,
      validators: [
        (v) => (v is String && !v.contains('@')) ? 'Invalid email' : null,
      ],
    ),
    FieldMeta(
      key: 'age',
      label: 'Age',
      type: FieldType.number,
      required: true,
    ),
  ],
  onSubmit: (result) async {
    final email = result.get<String>('email');
    final age   = result.get<num>('age');
    // save to your backend
  },
)
```

---

## Field Types

| Type | Description |
|------|-------------|
| `FieldType.text` | Single-line text input |
| `FieldType.number` | Numeric input (int or decimal) |
| `FieldType.date` | Date picker (returns `DateTime`) |
| `FieldType.dropdown` | Static or async dropdown |
| `FieldType.textArea` | Multi-line text input |
| `FieldType.image` | Image picker (returns `List<String>` paths) |
| `FieldType.custom` | Your own widget via a builder function |

---

## Cascading Dropdowns

When a dropdown depends on another field's value, the engine automatically:
- Reloads child items when the parent changes
- Clears child value when parent changes
- Hides the child until the parent has a value

```dart
FieldMeta(
  key: 'division',
  label: 'Division',
  type: FieldType.dropdown,
  dropdownSource: DropdownSource.async(fetchDivisions),
),
FieldMeta(
  key: 'district',
  label: 'District',
  type: FieldType.dropdown,
  dependsOn: 'division',
  dependency: FieldDependency(dependsOn: 'division'),
  dropdownSource: DropdownSource.async(
    (parentValue) async => fetchDistricts(parentValue),
  ),
),
```

---

## Custom Fields

Need a star rating, a signature pad, a toggle, or any widget? Use `FieldMeta.custom`:

```dart
FieldMeta.custom(
  key: 'rating',
  label: 'Rating',
  required: true,
  validators: [(v) => v == null ? 'Please rate' : null],
  builder: (context, value, onChanged, errorText) {
    return Column(
      children: [
        StarRatingWidget(
          value: value as int? ?? 0,
          onChanged: onChanged,
        ),
        if (errorText != null)
          Text(errorText, style: TextStyle(color: Colors.red)),
      ],
    );
  },
),
```

---

## Pre-filling Values (Edit Mode)

```dart
RjForm(
  fields: fields,
  initialValues: {
    'name': 'John Doe',
    'dob':  DateTime(1990, 5, 15),
    'country': 'bd',
  },
  onSubmit: (_) async {},
)
```

---

## External Controller

Use an external `FormController` when you need to read form state from outside the widget — e.g., to enable a button, validate programmatically, or reset the form.

```dart
final _ctrl = FormController();

@override
void dispose() {
  _ctrl.dispose();
  super.dispose();
}

// Trigger submit from outside
void _save() async {
  if (_ctrl.validate(fields)) {
    final result = _ctrl.toResult();
    // handle result
  }
}

// In build:
RjForm(
  fields: fields,
  controller: _ctrl,
  hideSubmitButton: true, // manage your own button
  onSubmit: (_) async {},
)
```

---

## Theming

```dart
RjForm(
  fields: fields,
  theme: RjFormTheme(
    primaryColor:    Colors.teal,
    borderRadius:    BorderRadius.circular(16),
    fieldSpacing:    24,
    fieldFillColor:  Colors.grey.shade50,
    borderColor:     Colors.grey.shade300,
    errorColor:      Colors.red,
  ),
  onSubmit: (_) async {},
)
```

---

## View Mode (Read-only)

```dart
RjForm(
  fields: fields,
  initialValues: existingRecord,
  viewOnly: true,           // all fields become read-only
  onSubmit: (_) async {},   // never called in view mode
)
```

---

## Conditional Visibility

```dart
FieldMeta(
  key: 'other_reason',
  label: 'Please specify',
  type: FieldType.textArea,
  dependency: FieldDependency(
    dependsOn: 'reason',
    condition: (value) => value == 'other',  // only show when reason == 'other'
  ),
),
```

---

## API Reference

### `FieldMeta`

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | Unique form field key |
| `label` | `String` | Display label |
| `type` | `FieldType` | Field type |
| `required` | `bool` | Required validation |
| `validators` | `List<FieldValidator>` | Custom validators |
| `dropdownSource` | `DropdownSource?` | Static or async item source |
| `dependsOn` | `String?` | Key of parent field (cascade reload) |
| `dependency` | `FieldDependency?` | Visibility condition |
| `firstDate` | `DateTime?` | Min date (date fields) |
| `lastDate` | `DateTime?` | Max date (date fields) |
| `maxImages` | `int` | Max images (default: 1) |
| `viewOnly` | `bool` | Read-only rendering |
| `hint` | `String?` | Placeholder text |
| `builder` | `CustomFieldBuilder?` | Custom widget builder |

### `DropdownSource`

```dart
DropdownSource.static(List<DropdownItem> items)
DropdownSource.async(Future<List<DropdownItem>> Function([dynamic parentValue]) loader)
```

### `FormController`

| Method | Description |
|--------|-------------|
| `setValue(key, value)` | Set a single value |
| `setAll(map)` | Replace all values |
| `clear()` | Reset form |
| `validate(fields)` | Run validation, returns bool |
| `toResult()` | Returns `FormResult` |
| `values` | Current form values map |
| `errors` | Current error map |
| `isDirty` | True if form has values |

---

## Author

**Returaj Proshad Shornocar** — Flutter & Mobile Software Engineer

[GitHub](https://github.com/ReturajProshad) · [LinkedIn](https://www.linkedin.com/in/returaj-proshad)

---

## License

MIT — see [LICENSE](LICENSE)
