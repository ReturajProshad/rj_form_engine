# rj_form_engine

**A schema-driven form engine for Flutter.**

Build complex forms from pure configuration. One external dependency (`image_picker`). Any state management.

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

- **13 field types** — text, number, date, dropdown, image upload, textarea, slider, time picker, spinner, toggle, radio, chip multi-select, custom
- **Custom fields** — inject any widget via `FieldMeta.custom`
- **Cascading dropdowns** — parent/child dependency with auto-reload and auto-clear
- **Async dropdown loading** — load items from APIs, databases, or caches
- **Static dropdowns** — pass a fixed list when no async call is needed
- **Built-in validation** — 20+ validators (email, phone, URL, password rules, date ranges, etc.)
- **Conditional visibility** — show/hide fields based on other field values
- **View / edit modes** — render read-only with a single flag
- **Pre-fill values** — for edit or clone mode
- **External controller** — read form state from outside the widget
- **`onChanged` callback** — react to individual field changes in real time
- **Error summary** — display all validation errors at the top of the form
- **Keyboard dismissal** — tap outside fields to dismiss the keyboard
- **Accessibility** — `Semantics` labels on all field widgets
- **Custom date/time formats** — use `dateFormat` and `timeFormat` on `FieldMeta`
- **Themeable** — one `RjFormTheme` controls all field styles
- **Minimal dependencies** — only `flutter` SDK + `image_picker`

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
        RjValidators.email(),
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

| Type | Description | Returns |
|------|-------------|---------|
| `FieldType.text` | Single-line text input | `String` |
| `FieldType.number` | Numeric input (int or decimal) | `num?` |
| `FieldType.date` | Date picker | `DateTime` |
| `FieldType.dropdown` | Static or async dropdown | `String?` (item id) |
| `FieldType.textArea` | Multi-line text input | `String` |
| `FieldType.image` | Image picker (gallery) | `List<String>` (file paths) |
| `FieldType.custom` | Your own widget via a builder function | Any |
| `FieldType.slider` | Horizontal slider with min/max | `double` |
| `FieldType.timePicker` | Time picker (clock UI) | `TimeOfDay` |
| `FieldType.spinner` | Number stepper with + / - buttons | `int` |
| `FieldType.toggle` | Boolean on/off switch | `bool` |
| `FieldType.radio` | Single-select radio list | `String` (option id) |
| `FieldType.chip` | Multi-select chip list | `List<String>` (option ids) |

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

## Real-time Change Tracking

React to field changes as the user types — useful for auto-save, analytics, or enabling/disabling buttons:

```dart
RjForm(
  fields: fields,
  onSubmit: (_) async {},
  onChanged: (key, value) {
    print('$key changed to: $value');
    // e.g., auto-save, enable submit button, etc.
  },
)
```

---

## Error Summary

Display all validation errors at the top of the form for better UX on long forms:

```dart
RjForm(
  fields: fields,
  onSubmit: (_) async {},
  showErrorsSummary: true,
)
```

---

## Custom Date/Time Formats

Control how dates and times are displayed:

```dart
// Date field with custom format
FieldMeta(
  key: 'dob',
  label: 'Date of Birth',
  type: FieldType.date,
  dateFormat: 'dd/MM/yyyy',  // or 'MM-dd-yyyy', 'yyyy.MM.dd', etc.
),

// Time field with 24-hour format
FieldMeta(
  key: 'meeting_time',
  label: 'Meeting Time',
  type: FieldType.timePicker,
  timeFormat: 'HH:mm',  // or 'h:mm a', 'HH:mm:ss', etc.
),
```

Supported date tokens: `yyyy`, `yy`, `MM`, `M`, `dd`, `d`
Supported time tokens: `HH`, `H`, `hh`, `h`, `mm`, `a`/`A`

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
| `dateFormat` | `String?` | Custom date format string |
| `timeFormat` | `String?` | Custom time format string |

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

### `RjValidators`

| Validator | Description |
|-----------|-------------|
| `email()` | Validates email format |
| `url()` | Validates URL format |
| `phone()` | Validates international phone |
| `bdPhone()` | Validates Bangladeshi mobile number |
| `minLength(n)` | Minimum string length |
| `maxLength(n)` | Maximum string length |
| `lengthBetween(min, max)` | String length range |
| `min(n)` | Minimum numeric value |
| `max(n)` | Maximum numeric value |
| `between(min, max)` | Numeric range |
| `positive()` | Positive number (> 0) |
| `nonNegative()` | Non-negative number (≥ 0) |
| `hasUppercase()` | At least one uppercase letter |
| `hasLowercase()` | At least one lowercase letter |
| `hasDigit()` | At least one digit |
| `hasSpecialChar()` | At least one special character |
| `pattern(regex)` | Custom regex pattern |
| `lettersOnly()` | Letters only |
| `digitsOnly()` | Digits only |
| `alphanumeric()` | Letters and digits only |
| `pastDate()` | Date must be in the past |
| `futureDate()` | Date must be in the future |
| `minSelect(n)` | Minimum selections (multi-select) |
| `maxSelect(n)` | Maximum selections (multi-select) |
| `matches(other)` | Values must match (e.g., confirm password) |
| `custom(fn)` | Wrap custom logic |

---

## Author

**Returaj Proshad Shornocar** — Flutter & Mobile Software Engineer

[GitHub](https://github.com/ReturajProshad) · [LinkedIn](https://www.linkedin.com/in/returaj-proshad)

---

## License

MIT — see [LICENSE](LICENSE)
