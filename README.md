# rj_form_engine

**A schema-driven form engine for Flutter.** Build complex, validated forms from pure configuration — no boilerplate, no repetitive wiring.

[![pub package](https://img.shields.io/pub/v/rj_form_engine.svg)](https://pub.dev/packages/rj_form_engine)
[![pub points](https://img.shields.io/pub/points/rj_form_engine)](https://pub.dev/packages/rj_form_engine/score)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why rj_form_engine?

Building forms in Flutter is repetitive. Every screen has the same patterns — text fields, dropdowns, date pickers, image uploads — all wired up by hand, validated manually, and state-managed individually.

`rj_form_engine` replaces all of that with a **schema**. You define what your form looks like. The engine renders it, validates it, and returns the data.

```dart
RjForm(
  fields: [
    FieldMeta(key: 'name',    label: 'Full Name',     type: FieldType.text,     required: true),
    FieldMeta(key: 'dob',     label: 'Date of Birth', type: FieldType.date),
    FieldMeta(key: 'country', label: 'Country',       type: FieldType.dropdown,
      dropdownSource: DropdownSource.async(fetchCountries),
    ),
    FieldMeta(key: 'city',    label: 'City',          type: FieldType.dropdown,
      dependency: FieldDependency(dependsOn: 'country'), // cascades automatically
      dropdownSource: DropdownSource.async(
        ({parentValue}) async => fetchCities(parentValue: parentValue),
      ),
    ),
  ],
  onSubmit: (result) async {
    print(result.values); // {'name': 'John', 'dob': DateTime(...), ...}
  },
)
```

---

## Features

- **13 field types** — text, number, date, dropdown, textarea, image upload, slider, time picker, spinner, toggle, radio, chip multi-select, custom
- **Custom fields** — inject any widget via `FieldMeta.custom`
- **Cascading dropdowns** — parent/child dependency with auto-reload and auto-clear
- **Async dropdown loading** — load items from APIs, databases, or caches
- **Static dropdowns** — pass a fixed list when no async call is needed
- **25+ built-in validators** — email, phone, URL, password rules, date ranges, and more
- **Conditional visibility** — show/hide fields based on other field values
- **View / edit modes** — render read-only with a single flag
- **Pre-fill values** — for edit or clone mode
- **External controller** — read form state from outside the widget
- **`onChanged` callback** — react to individual field changes in real time
- **Error summary** — display all validation errors at the top of the form
- **Keyboard dismissal** — tap outside fields to dismiss the keyboard
- **Accessibility** — `Semantics` labels on all field widgets
- **Custom date/time formats** — use `dateFormat` and `timeFormat` on `FieldMeta`
- **Typed field config** — `SliderConfig`, `DateConfig`, `ImageConfig`, and more via `FieldConfig`
- **Themeable** — one `RjFormTheme` controls all field styles
- **Minimal dependencies** — only `flutter` SDK + `image_picker`
- **State-management agnostic** — works with Provider, Riverpod, Bloc, GetX, or nothing at all

---

## Preview

<!-- TODO: Add a GIF or screenshot preview here.
     Recommended size: 480x800, under 2MB.
     Example: ![rj_form_engine preview](https://raw.githubusercontent.com/ReturajProshad/rj_form_engine/main/preview.gif)
-->

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rj_form_engine: ^0.1.0
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

A minimal form with validation in under 20 lines:

```dart
import 'package:rj_form_engine/rj_form_engine.dart';

RjForm(
  fields: [
    FieldMeta(
      key: 'email',
      label: 'Email Address',
      type: FieldType.text,
      required: true,
      hint: 'Enter your email',
      validators: [RjValidators.email()],
    ),
    FieldMeta(
      key: 'age',
      label: 'Age',
      type: FieldType.number,
      required: true,
      validators: [RjValidators.min(18, message: 'Must be 18 or older')],
    ),
  ],
  onSubmit: (result) async {
    final email = result.get<String>('email');
    final age   = result.get<num>('age');
    // Send to your backend
  },
)
```

---

## Complete Example

A registration form demonstrating multiple field types, cascading dropdowns, conditional visibility, and custom validation:

```dart
import 'package:rj_form_engine/rj_form_engine.dart';

class RegistrationForm extends StatelessWidget {
  const RegistrationForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RjForm(
          fields: [
            // Section header
            FieldMeta.section(key: 'personal_info', label: 'Personal Information'),

            // Text field
            FieldMeta(
              key: 'full_name',
              label: 'Full Name',
              type: FieldType.text,
              required: true,
              hint: 'John Doe',
              validators: [RjValidators.minLength(2)],
            ),

            // Email with validation
            FieldMeta(
              key: 'email',
              label: 'Email',
              type: FieldType.text,
              required: true,
              validators: [RjValidators.email()],
            ),

            // Password with rules
            FieldMeta(
              key: 'password',
              label: 'Password',
              type: FieldType.text,
              required: true,
              obscureText: true,
              validators: [
                RjValidators.minLength(8),
                RjValidators.hasUppercase(),
                RjValidators.hasDigit(),
                RjValidators.hasSpecialChar(),
              ],
            ),

            // Date picker
            FieldMeta(
              key: 'dob',
              label: 'Date of Birth',
              type: FieldType.date,
              required: true,
              dateFormat: 'dd/MM/yyyy',
              validators: [RjValidators.pastDate()],
            ),

            // Section header
            FieldMeta.section(key: 'location', label: 'Location'),

            // Async dropdown (country)
            FieldMeta(
              key: 'country',
              label: 'Country',
              type: FieldType.dropdown,
              required: true,
              dropdownSource: DropdownSource.async(
                ({parentValue}) async => fetchCountries(),
              ),
            ),

            // Cascading dropdown (city — depends on country)
            FieldMeta(
              key: 'city',
              label: 'City',
              type: FieldType.dropdown,
              required: true,
              dependency: FieldDependency(dependsOn: 'country'),
              dropdownSource: DropdownSource.async(
                ({parentValue}) async => fetchCities(parentValue: parentValue),
              ),
            ),

            // Conditional field — only shows when country == 'bd'
            FieldMeta(
              key: 'nid_number',
              label: 'NID Number',
              type: FieldType.text,
              dependency: FieldDependency(
                dependsOn: 'country',
                condition: (value) => value == 'bd',
              ),
              validators: [RjValidators.digitsOnly()],
            ),

            // Radio buttons
            FieldMeta(
              key: 'gender',
              label: 'Gender',
              type: FieldType.radio,
              required: true,
              options: const [
                DropdownItem(id: 'male', label: 'Male'),
                DropdownItem(id: 'female', label: 'Female'),
                DropdownItem(id: 'other', label: 'Other'),
              ],
            ),

            // Chip multi-select
            FieldMeta(
              key: 'interests',
              label: 'Interests',
              type: FieldType.chip,
              options: const [
                DropdownItem(id: 'tech', label: 'Technology'),
                DropdownItem(id: 'sports', label: 'Sports'),
                DropdownItem(id: 'music', label: 'Music'),
                DropdownItem(id: 'travel', label: 'Travel'),
              ],
              validators: [RjValidators.minSelect(1, message: 'Select at least one')],
            ),

            // Toggle
            FieldMeta(
              key: 'accept_terms',
              label: 'Accept Terms & Conditions',
              type: FieldType.toggle,
              required: true,
            ),
          ],
          onSubmit: (result) async {
            // result.values contains all field data
            await registerUser(result.values);
          },
          onSuccess: (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')),
            );
          },
          showErrorsSummary: true,
          theme: RjFormTheme(
            primaryColor: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<List<DropdownItem>> fetchCountries() async {
    // Replace with your API call
    return const [
      DropdownItem(id: 'bd', label: 'Bangladesh'),
      DropdownItem(id: 'us', label: 'United States'),
      DropdownItem(id: 'uk', label: 'United Kingdom'),
    ];
  }

  Future<List<DropdownItem>> fetchCities({String? parentValue}) async {
    // Replace with your API call
    final cities = {
      'bd': [const DropdownItem(id: 'dhaka', label: 'Dhaka')],
      'us': [const DropdownItem(id: 'nyc', label: 'New York')],
      'uk': [const DropdownItem(id: 'london', label: 'London')],
    };
    return cities[parentValue] ?? [];
  }

  Future<void> registerUser(Map<String, dynamic> data) async {
    // Replace with your API call
    await Future.delayed(const Duration(seconds: 1));
    print('Registered: $data');
  }
}
```

---

## Core Concepts

### FieldMeta

`FieldMeta` is the blueprint for a single form field. Every field in your form is defined by one `FieldMeta` instance.

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | **Required.** Unique identifier for the field. Used to read/write values. |
| `label` | `String` | **Required.** Display label shown above the field. |
| `type` | `FieldType` | **Required.** Determines which widget is rendered. |
| `required` | `bool` | When `true`, the field must have a non-empty value to pass validation. |
| `validators` | `List<FieldValidator>` | Additional validation functions. See [Validation](#validation). |
| `hint` | `String?` | Placeholder text displayed inside the field. |
| `dependency` | `FieldDependency?` | Controls visibility based on another field's value. See [Dependencies](#conditional-visibility--dependencies). |
| `dropdownSource` | `DropdownSource?` | Item source for dropdown fields. Accepts static or async data. |
| `options` | `List<DropdownItem>` | Options for radio and chip fields. |
| `config` | `FieldConfig?` | Typed configuration (e.g., `SliderConfig`, `DateConfig`). Takes precedence over flat params. |
| `viewOnly` | `bool` | When `true`, renders the field as read-only. |
| `builder` | `CustomFieldBuilder?` | Custom widget builder for `FieldType.custom`. |

**Typed config** (preferred over flat params):

```dart
// Slider with typed config
FieldMeta(
  key: 'volume',
  label: 'Volume',
  type: FieldType.slider,
  config: const SliderConfig(min: 0.0, max: 100.0, divisions: 10),
),

// Date with typed config
FieldMeta(
  key: 'deadline',
  label: 'Deadline',
  type: FieldType.date,
  config: DateConfig(
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    format: 'yyyy-MM-dd',
  ),
),
```

### FormController

`FormController` manages form state externally. It extends `ChangeNotifier` and works with any state management approach.

```dart
final _controller = FormController();

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// Read values at any time
print(_controller.values);

// Validate programmatically
if (_controller.validate(fields)) {
  final result = _controller.toResult();
  // handle result
}

// Set or clear values
_controller.setValue('name', 'John');
_controller.clear();
```

**When to use an external controller:**

- Submit from outside the form (e.g., AppBar action, FAB)
- Enable/disable a button based on form state
- Auto-save on field changes
- Reset the form programmatically

### Validation

Validation happens in two layers:

1. **`required: true`** — built-in check for null, empty strings, and empty lists.
2. **`validators`** — a list of `FieldValidator` functions that run after the required check.

Each validator returns `String?` — an error message if invalid, or `null` if valid.

```dart
FieldMeta(
  key: 'password',
  label: 'Password',
  type: FieldType.text,
  required: true,
  validators: [
    RjValidators.minLength(8),
    RjValidators.hasUppercase(),
    RjValidators.hasDigit(),
    RjValidators.hasSpecialChar(),
    RjValidators.custom(
      (value) => value.toString().contains('123')
          ? 'Password must not contain "123"'
          : null,
    ),
  ],
),
```

**Available validators:**

| Validator | Description |
|-----------|-------------|
| `required()` | Non-null, non-empty check |
| `email()` | Email format |
| `url()` | HTTP/HTTPS URL format |
| `phone()` | International phone (7-15 digits) |
| `bdPhone()` | Bangladeshi mobile number |
| `minLength(n)` / `maxLength(n)` | String length bounds |
| `lengthBetween(min, max)` | String length range |
| `min(n)` / `max(n)` | Numeric value bounds |
| `between(min, max)` | Numeric range |
| `positive()` / `nonNegative()` | Positive / non-negative numbers |
| `hasUppercase()` / `hasLowercase()` / `hasDigit()` / `hasSpecialChar()` | Password rule checks |
| `pattern(regex)` | Custom regex |
| `lettersOnly()` / `digitsOnly()` / `alphanumeric()` | Character type checks |
| `pastDate()` / `futureDate()` | Date range checks |
| `minSelect(n)` / `maxSelect(n)` | Multi-select bounds |
| `matches(other)` | Value matching (e.g., confirm password) |
| `custom(fn)` | Wrap any custom validation logic |

> **Note:** All validators except `required()` skip null/empty values. Combine them with `required: true` to enforce presence.

### Conditional Visibility & Dependencies

Fields can be shown or hidden based on other field values using `FieldDependency`:

```dart
// Show only when 'reason' equals 'other'
FieldMeta(
  key: 'other_reason',
  label: 'Please specify',
  type: FieldType.textArea,
  dependency: FieldDependency(
    dependsOn: 'reason',
    condition: (value) => value == 'other',
  ),
),
```

**Cascading dropdowns** use the same mechanism. When the parent dropdown changes, the child automatically reloads its items and clears its current value:

```dart
FieldMeta(
  key: 'city',
  label: 'City',
  type: FieldType.dropdown,
  dependency: FieldDependency(dependsOn: 'country'),
  dropdownSource: DropdownSource.async(
    ({parentValue}) async => fetchCities(parentValue: parentValue),
  ),
),
```

### Custom Fields

Use `FieldMeta.custom` to embed any widget into your form. The builder receives the full `FieldMeta`, current value, an `onChanged` callback, and any error text:

```dart
FieldMeta.custom(
  key: 'rating',
  label: 'Rating',
  required: true,
  validators: [(v) => v == null ? 'Please select a rating' : null],
  builder: (context, field, value, onChanged, errorText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(field.label, style: const TextStyle(fontWeight: FontWeight.w500)),
        StarRatingWidget(
          value: value as int? ?? 0,
          onChanged: onChanged,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  },
),
```

---

## Field Types

| Type | Widget | Returns | Common Use |
|------|--------|---------|------------|
| `FieldType.text` | `RjTextField` | `String` | Names, emails, passwords |
| `FieldType.number` | `RjNumberField` | `num?` | Age, price, quantity |
| `FieldType.date` | `RjDateField` | `DateTime` | Birth dates, deadlines |
| `FieldType.dropdown` | `RjDropdownField` | `String?` (item id) | Country, category, status |
| `FieldType.textArea` | `RjTextField` | `String` | Descriptions, comments |
| `FieldType.image` | `RjImageField` | `List<String>` (file paths) | Photo uploads |
| `FieldType.slider` | `RjSliderField` | `double` | Volume, rating, range |
| `FieldType.timePicker` | `RjTimePickerField` | `TimeOfDay` | Meeting time, schedule |
| `FieldType.spinner` | `RjSpinnerField` | `int` | Quantity, count |
| `FieldType.toggle` | `RjToggleField` | `bool` | Accept terms, enable feature |
| `FieldType.radio` | `RjRadioField` | `String` (option id) | Gender, single choice |
| `FieldType.chip` | `RjChipField` | `List<String>` (option ids) | Tags, interests, skills |
| `FieldType.custom` | Your widget | Any | Signature pad, star rating, maps |

---

## Common Patterns

### Pre-filling Values (Edit Mode)

```dart
RjForm(
  fields: fields,
  initialValues: {
    'name': 'John Doe',
    'email': 'john@example.com',
    'country': 'bd',
    'dob': DateTime(1990, 5, 15),
  },
  onSubmit: (_) async {},
)
```

### External Controller with Custom Submit Button

```dart
class MyForm extends StatefulWidget {
  const MyForm({super.key});

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _controller = FormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.validate(fields)) {
      final result = _controller.toResult();
      // handle result
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RjForm(
            fields: fields,
            controller: _controller,
            hideSubmitButton: true,
            onSubmit: (_) async {},
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
```

### View Mode (Read-only)

```dart
RjForm(
  fields: fields,
  initialValues: existingRecord,
  viewOnly: true,
  onSubmit: (_) async {}, // Never called in view mode
)
```

### Real-time Change Tracking

```dart
RjForm(
  fields: fields,
  onSubmit: (_) async {},
  onChanged: (key, value) {
    // Useful for auto-save, analytics, or enabling buttons
    print('$key changed to: $value');
  },
)
```

### Error Summary

```dart
RjForm(
  fields: fields,
  onSubmit: (_) async {},
  showErrorsSummary: true,
  // Optional: customize the summary message
  errorsSummaryBuilder: (errors) {
    return 'Please fix ${errors.length} error(s) before submitting.';
  },
)
```

### Theming

```dart
RjForm(
  fields: fields,
  theme: RjFormTheme(
    primaryColor:    const Color(0xFF0D9488),
    borderColor:     const Color(0xFFD1D5DB),
    errorColor:      const Color(0xFFDC2626),
    borderRadius:    BorderRadius.circular(12),
    fieldSpacing:    24,
    fieldFillColor:  Colors.grey.shade50,
    labelStyle:      const TextStyle(fontWeight: FontWeight.w600),
    submitButtonColor: const Color(0xFF0D9488),
  ),
  onSubmit: (_) async {},
)
```

---

## Best Practices

1. **Always provide explicit `key` values.** Keys are used as identifiers for form state. Duplicate keys cause silent data overwrites.

2. **Combine `required: true` with validators.** Validators skip empty values by design. Use `required` to enforce presence, then validators to enforce format.

3. **Use typed `FieldConfig` over flat params.** `SliderConfig`, `DateConfig`, `ImageConfig`, etc., are the preferred way to configure field-specific behavior. Flat params (`sliderMin`, `dateFormat`, etc.) are kept for backward compatibility.

4. **Dispose external controllers.** If you create a `FormController` yourself, call `dispose()` in your widget's `dispose()` method. Controllers managed internally by `RjForm` are disposed automatically.

5. **Use `DropdownSource.async` for large lists.** Static dropdowns load all items at widget build. For lists fetched from an API or database, use `DropdownSource.async` to avoid blocking the UI thread.

6. **Provide unique keys for sections.** `FieldMeta.section` requires an explicit `key` parameter. Duplicate section keys will trigger an assertion in debug mode.

7. **Handle type casting in `FormResult.get<T>()`.** Values are stored with their native types (`DateTime`, `double`, `List<String>`, etc.). If you cast to the wrong type, `get<T>()` returns `null`. Check the [Field Types](#field-types) table for expected return types.

---

## Limitations

- **Image picker supports gallery only.** Camera capture is not currently supported.
- **No built-in form state persistence.** Form data is lost if the app is killed in the background. Implement your own persistence layer if needed.
- **Single-column layout.** Fields render vertically. Multi-column or grid layouts require custom field builders.
- **No i18n built-in.** Labels, hints, and error messages are plain strings. You must handle localization yourself (e.g., via `AppLocalizations.of(context)`).
- **`FormResult.get<T>()` returns `null` on type mismatch.** If you request `result.get<int>('age')` but the stored value is a `String`, you get `null` silently. Always use the correct type.

---

## Roadmap

- [ ] Camera support for image fields
- [ ] Multi-column / grid layout support
- [ ] Built-in i18n / localization
- [ ] Form state persistence (auto-save / restore)
- [ ] File upload field (non-image)
- [ ] Rich text / markdown field
- [ ] Dynamic field addition/removal at runtime
- [ ] Integration tests

---

## Contributing

Contributions are welcome! If you find a bug or have a feature request:

1. [Open an issue](https://github.com/ReturajProshad/rj_form_engine/issues) with a clear description and reproduction steps.
2. For code contributions, please fork the repo, create a feature branch, and submit a pull request.
3. Follow the existing code style and include tests for new functionality.

---

## Author

**Returaj Proshad Shornocar** — Flutter & Mobile Software Engineer

[GitHub](https://github.com/ReturajProshad) · [LinkedIn](https://www.linkedin.com/in/returaj-proshad)

---

## License

MIT — see [LICENSE](LICENSE)
