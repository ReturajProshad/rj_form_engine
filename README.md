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
    FieldMeta.text(key: 'name', label: 'Full Name', required: true),
    FieldMeta.date(key: 'dob', label: 'Date of Birth'),
    FieldMeta.dropdown(key: 'country', label: 'Country',
      dropdownSource: DropdownSource.async(fetchCountries),
    ),
    FieldMeta.dropdown(key: 'city', label: 'City',
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

- **Typed factory constructors** — `FieldMeta.text()`, `.number()`, `.date()`, `.dropdown()` and more — each surfaces only the params that make sense for that field type, with full IDE autocompletion
- **Responsive grid layout** — mobile-first 12-column grid with `RjSpan` (`full`/`half`/`third`/`quarter`) and `RjLayout`. Phone always stacks full-width; tablet/desktop uses declared spans automatically
- **Label customization** — hide labels (`showLabel: false`) or replace them with styled text (`RjLabelText`) or any widget (`RjLabelCustom`)
- **Auto-derivation** — fields that auto-compute their value from other fields (e.g., `total = price × quantity`)
- **Label shadowing** — dropdown labels are stored alongside IDs, giving `compute` functions instant access to human-readable text
- **Chained derivations** — A → B → C cascades update in a single pass
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
- **Keyboard dismissal** — Tap outside fields to dismiss the keyboard.
- **Accessibility** — `Semantics` labels on all field widgets
- **Custom date/time formats** — use `dateFormat` and `timeFormat` on `FieldMeta`
- **Typed field config** — `SliderConfig`, `DateConfig`, `ImageConfig`, and more via `FieldConfig`
- **Themeable** — one `RjFormTheme` controls all field styles
- **Minimal dependencies** — only `flutter` SDK + `image_picker`
- **State-management agnostic** — works with Provider, Riverpod, Bloc, GetX, or nothing at all

---


## 📸 Preview

### Video Demo
See the engine in action, including dynamic validation, cascading logic, and smooth field transitions:

https://github.com/user-attachments/assets/420abb19-a3e8-4ae9-b4c7-3b6e0881237c

### Screenshots

| Default Fields | Automatic Error Handling | Dark/Custom Theme |
|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/3cebb8a9-8e70-49f0-a8bb-c4df34855e14" width="250"> | <img src="https://github.com/user-attachments/assets/189e073e-af23-48a3-a379-57e9a80d1ccd" width="250"> | <img src="https://github.com/user-attachments/assets/d31624e9-01c0-4ec3-8ac0-49d0a229f68d" width="250"> |

| Custom Fields Support | Derivation Fields Example Page | Label Shadowing & Customization | Form Entry Page |
|:---:|:---:|:---:|:---:|
| <img src="https://github.com/user-attachments/assets/b0f4f59e-860b-4a81-9180-bdc941f2f5f4" width="250">|  <img width="250" alt="derivation Demo -1" src="https://github.com/user-attachments/assets/1faaada4-d49d-4ed7-afe0-bc1c213466bc" />| <img width="250" alt="label_customization" src="https://github.com/user-attachments/assets/c66d0dfc-74ba-416a-96b0-1c2f41cd9e86" /> | <img src="https://github.com/user-attachments/assets/9fc8ac3b-8acc-4029-a5f7-07fd6d42ed84" width="250"> |

|Responsive demo 1|Responsive demo 2|
|:---:|:---:|
| <img width="500" height="500" alt="make-your form dynamically responsive as you want" src="https://github.com/user-attachments/assets/78abe53e-4892-4804-af17-00b47c4fb136" />|<img width="600" height="500" alt="responsive-desktop" src="https://github.com/user-attachments/assets/acfa46b6-db5d-4190-91ec-75f840ee96e9" />


---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rj_form_engine: ^1.0.0
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
    FieldMeta.text(
      key: 'email',
      label: 'Email Address',
      required: true,
      hint: 'Enter your email',
      validators: [RjValidators.email()],
    ),
    FieldMeta.number(
      key: 'age',
      label: 'Age',
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

            // Text fields — side by side on tablet+
            FieldMeta.text(
              key: 'full_name',
              label: 'Full Name',
              required: true,
              hint: 'John Doe',
              validators: [RjValidators.minLength(2)],
              layout: const RjLayout(md: RjSpan.half),
            ),
            FieldMeta.text(
              key: 'email',
              label: 'Email',
              required: true,
              validators: [RjValidators.email()],
              layout: const RjLayout(md: RjSpan.half),
            ),

            // Password with rules — standalone for security
            FieldMeta.text(
              key: 'password',
              label: 'Password',
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
            FieldMeta.date(
              key: 'dob',
              label: 'Date of Birth',
              required: true,
              dateFormat: 'dd/MM/yyyy',
              validators: [RjValidators.pastDate()],
            ),

            // Derived field — total = price × quantity
            FieldMeta.number(key: 'quantity', label: 'Quantity', required: true),
            FieldMeta.number(
              key: 'total_price',
              label: 'Total Price (auto)',
              derivation: FieldDerivation(
                derivesFrom: ['quantity'],
                compute: (state) {
                  final qty = (state['quantity'] as num?)?.toDouble() ?? 0;
                  final basePrice = 29.99;
                  return qty * basePrice;
                },
              ),
            ),

            // Section header
            FieldMeta.section(key: 'location', label: 'Location'),

            // Async dropdown (country)
            FieldMeta.dropdown(
              key: 'country',
              label: 'Country',
              required: true,
              dropdownSource: DropdownSource.async(
                ({parentValue}) async => fetchCountries(),
              ),
            ),

            // Cascading dropdown (city — depends on country)
            FieldMeta.dropdown(
              key: 'city',
              label: 'City',
              required: true,
              dependency: FieldDependency(dependsOn: 'country'),
              dropdownSource: DropdownSource.async(
                ({parentValue}) async => fetchCities(parentValue: parentValue),
              ),
            ),

            // Conditional field — only shows when country == 'bd'
            FieldMeta.text(
              key: 'nid_number',
              label: 'NID Number',
              dependency: FieldDependency(
                dependsOn: 'country',
                condition: (value) => value == 'bd',
              ),
              validators: [RjValidators.digitsOnly()],
            ),

            // Radio buttons + Chip — side by side on tablet
            FieldMeta.radio(
              key: 'gender',
              label: 'Gender',
              required: true,
              options: const [
                DropdownItem(id: 'male', label: 'Male'),
                DropdownItem(id: 'female', label: 'Female'),
                DropdownItem(id: 'other', label: 'Other'),
              ],
              layout: const RjLayout(md: RjSpan.half),
            ),
            FieldMeta.chip(
              key: 'interests',
              label: 'Interests',
              options: const [
                DropdownItem(id: 'tech', label: 'Technology'),
                DropdownItem(id: 'sports', label: 'Sports'),
                DropdownItem(id: 'music', label: 'Music'),
                DropdownItem(id: 'travel', label: 'Travel'),
              ],
              validators: [RjValidators.minSelect(1, message: 'Select at least one')],
              layout: const RjLayout(md: RjSpan.half),
            ),

            // Toggle
            FieldMeta.toggle(
              key: 'accept_terms',
              label: 'Accept Terms & Conditions',
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

Use the **typed factory constructors** to create fields — each factory surfaces only the params relevant to that field type:

```dart
FieldMeta.text(key: 'name', label: 'Name', hint: 'Enter name')
FieldMeta.number(key: 'age', label: 'Age', required: true)
FieldMeta.date(key: 'dob', label: 'Date of Birth', dateFormat: 'dd/MM/yyyy')
FieldMeta.dropdown(key: 'country', label: 'Country', dropdownSource: ...)
FieldMeta.custom(key: 'rating', label: 'Rating', builder: ...)
// etc.
```

| Property | Type | Description |
|----------|------|-------------|
| `key` | `String` | **Required.** Unique identifier for the field. Used to read/write values. |
| `label` | `String` | **Required.** Display label shown above the field. |
| `required` | `bool` | When `true`, the field must have a non-empty value to pass validation. |
| `validators` | `List<FieldValidator>` | Additional validation functions. See [Validation](#validation). |
| `hint` | `String?` | Placeholder text displayed inside the field. |
| `dependency` | `FieldDependency?` | Controls visibility based on another field's value. |
| `derivation` | `FieldDerivation?` | Auto-computes this field's value from other fields. |
| `layout` | `RjLayout?` | Responsive grid span. See [Responsive Grid](#responsive-grid). |
| `showLabel` | `bool` | When `false`, hides the field label entirely. Default `true`. |
| `labelConfig` | `RjLabel?` | Custom label override. Use `RjLabelText` for styled text or `RjLabelCustom` for any widget. |
| `dropdownSource` | `DropdownSource?` | Item source for dropdown fields. Accepts static or async data. |
| `options` | `List<DropdownItem>` | Options for radio and chip fields. |
| `config` | `FieldConfig?` | Typed configuration (e.g., `SliderConfig`, `DateConfig`). |
| `viewOnly` | `bool` | When `true`, renders the field as read-only. |
| `builder` | `CustomFieldBuilder?` | Custom widget builder for `FieldType.custom`. |

**Typed config** (preferred over flat params):

```dart
FieldMeta.slider(
  key: 'volume',
  label: 'Volume',
  config: const SliderConfig(min: 0.0, max: 100.0, divisions: 10),
)

FieldMeta.date(
  key: 'deadline',
  label: 'Deadline',
  config: DateConfig(
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    format: 'yyyy-MM-dd',
  ),
)
```

### FieldDerivation (Auto-Computed Fields)

Fields can auto-compute their value from other fields using `FieldDerivation`. The derivation declares *which fields it derives from* and *how to compute the value*:

```dart
FieldMeta.number(
  key: 'total',
  label: 'Total',
  derivation: FieldDerivation(
    derivesFrom: ['price', 'quantity'],
    compute: (state) {
      final price = (state['price'] as num?)?.toDouble() ?? 0;
      final qty   = (state['quantity'] as num?)?.toDouble() ?? 0;
      return price * qty;
    },
  ),
)
```

**How it works:**

1. When `price` or `quantity` changes, the engine finds all fields whose `derivesFrom` includes the changed key.
2. It runs the `compute` function with the full form state map and stores the result.
3. Derived fields are automatically **read-only** — users cannot type into them.
4. Chained derivations (A → B → C) update in a single pass automatically.

**Label Shadowing for Dropdowns:**

Since dropdowns store IDs but derivations often need labels, the engine automatically stores the selected label as `{key}Label` alongside the ID. For example, selecting `"Dairy Cows"` from a `groupId` dropdown stores both:

- `groupId = "5"` (the ID)
- `groupIdLabel = "Dairy Cows"` (the label)

Your `compute` function can then read labels directly:

```dart
FieldDerivation(
  derivesFrom: ['category', 'item'],
  compute: (state) {
    final cat  = state['categoryLabel'] ?? '';
    final item = state['itemLabel'] ?? '';
    return [cat, item].where((p) => p.isNotEmpty).join(' - ');
  },
)
```

**Edit Mode:**

When loading existing data with `initialValues` or `setAll()`, call `recomputeAllDerivations()` to ensure computed fields reflect the loaded data:

```dart
controller.setAll(loadedData);
controller.recomputeAllDerivations(fields);
```

This is called automatically when using `RjForm(initialValues: ...)`.

### Label Customization

By default, every field renders its `label` text above the input. You can control or replace this with `showLabel` and `labelConfig`:

```dart
// Hide the label entirely
FieldMeta.text(
  key: 'no_label',
  label: 'Hidden Label',
  showLabel: false,
  hint: 'No label shown above',
)

// Styled text label via RjLabelText
FieldMeta.text(
  key: 'styled_label',
  label: 'Default (not shown)',
  labelConfig: const RjLabelText(
    text: 'Styled Label',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
  ),
)

// Custom widget label via RjLabelCustom
FieldMeta.number(
  key: 'custom_label',
  label: 'Default (not shown)',
  labelConfig: RjLabelCustom((context) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 18),
        SizedBox(width: 8),
        Text('Custom Widget Label'),
      ],
    );
  }),
)
```

**How it works:**
- `showLabel` (default `true`) — when `false`, no label is rendered at all.
- `labelConfig` — when set and `showLabel` is `true`, the default label is suppressed and the custom `RjLabel` widget is rendered above the input field.
- `RjLabelText` provides full text styling (`style`, `textAlign`, `maxLines`, `overflow`, `padding`).
- `RjLabelCustom` accepts a `WidgetBuilder` for any custom widget.

### Responsive Grid

Fields can be laid out side-by-side on tablet and desktop screens using `RjLayout` and `RjSpan`. On phones (below 768px), all fields automatically stack full-width — no configuration needed.

```dart
FieldMeta.text(
  key: 'first_name',
  label: 'First Name',
  required: true,
  layout: const RjLayout(md: RjSpan.half),
)
```

**How it works:**

- The engine uses a mobile-first **12-column grid**. Each field declares how many columns it occupies via `RjSpan`.
- Consecutive fields are auto-grouped into rows. When a field would exceed 12 columns, it wraps to the next row.
- Sections (`FieldMeta.section`) automatically break the current row and start fresh.
- Fields without a `layout` default to full width (12 columns) — backward compatible.

**RjSpan values:**

| Span | Columns | Typical layout |
|------|---------|----------------|
| `RjSpan.full` | 12 | 1 per row (default) |
| `RjSpan.half` | 6 | 2 per row |
| `RjSpan.third` | 4 | 3 per row |
| `RjSpan.quarter` | 3 | 4 per row |

**Breakpoint behavior:**

| Screen | Width | Behavior |
|--------|-------|----------|
| Phone | <768px | All fields forced to 12 cols (full-width) |
| Tablet | ≥768px | Respects `md` span |
| Desktop | ≥1024px | Uses `lg` if provided, otherwise falls back to `md` |

**Desktop override:**

```dart
FieldMeta.text(
  key: 'description',
  label: 'Description',
  layout: const RjLayout(md: RjSpan.half, lg: RjSpan.third),
)
```

**Typical ERP form (side-by-side layout):**

```dart
RjForm(
  fields: [
    FieldMeta.section(key: 'employee', label: 'Employee Details'),
    FieldMeta.text(key: 'first_name', label: 'First Name',
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.text(key: 'last_name', label: 'Last Name',
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.text(key: 'email', label: 'Email',
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.number(key: 'phone', label: 'Phone',
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.dropdown(key: 'department', label: 'Department',
      dropdownSource: DropdownSource.static(departments),
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.dropdown(key: 'position', label: 'Position',
      dropdownSource: DropdownSource.static(positions),
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.section(key: 'comp', label: 'Compensation'),
    FieldMeta.number(key: 'salary', label: 'Base Salary',
      layout: const RjLayout(md: RjSpan.half)),
    FieldMeta.slider(key: 'bonus', label: 'Bonus %',
      sliderMin: 0, sliderMax: 100, sliderDivisions: 100,
      layout: const RjLayout(md: RjSpan.half)),
  ],
)
```

> On a phone, every field stacks vertically — perfectly readable. On a tablet or desktop, `first_name` + `last_name`, `email` + `phone`, `department` + `position`, and `salary` + `bonus` line up side by side automatically.

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

// Recompute derived fields after bulk-loading data
_controller.setAll(loadedData);
_controller.recomputeAllDerivations(fields);
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
FieldMeta.text(
  key: 'password',
  label: 'Password',
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
FieldMeta.textArea(
  key: 'other_reason',
  label: 'Please specify',
  dependency: FieldDependency(
    dependsOn: 'reason',
    condition: (value) => value == 'other',
  ),
),
```

**Cascading dropdowns** use the same mechanism. When the parent dropdown changes, the child automatically reloads its items and clears its current value:

```dart
FieldMeta.dropdown(
  key: 'city',
  label: 'City',
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

### Auto-Computed Fields (Derivation)

```dart
RjForm(
  fields: [
    FieldMeta.number(key: 'price', label: 'Price', required: true),
    FieldMeta.number(key: 'quantity', label: 'Quantity', required: true),
    FieldMeta.number(
      key: 'total',
      label: 'Total (auto)',
      derivation: FieldDerivation(
        derivesFrom: ['price', 'quantity'],
        compute: (state) {
          final price = (state['price'] as num?)?.toDouble() ?? 0;
          final qty   = (state['quantity'] as num?)?.toDouble() ?? 0;
          return price * qty;
        },
      ),
    ),
  ],
  onSubmit: (_) async {},
)
```

> Derived fields are automatically read-only. Users can edit `price` and `quantity`; `total` updates instantly.

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

## Examples & Demo

A minimal working example is included in the `/example` folder for quick testing.

For a full-featured demo application with multiple screens and advanced use cases, check:

👉 [https://github.com/ReturajProshad/rj_form_engine_demo](https://github.com/ReturajProshad/rj_form_engine_demo)

### Run minimal example

```bash
git clone https://github.com/ReturajProshad/rj_form_engine
cd rj_form_engine/example
flutter pub get
flutter run
```

---
## Limitations

- **Image picker supports gallery only.** Camera capture is not currently supported. For camera or file picker functionality, use a custom field via `FieldMeta.custom`.
- **No built-in form state persistence.** Form data is lost if the app is killed in the background. Implement your own persistence layer if needed.
- **No i18n built-in.** Labels, hints, and error messages are plain strings. You must handle localization yourself (e.g., via `AppLocalizations.of(context)`).
- **`FormResult.get<T>()` returns `null` on type mismatch.** If you request `result.get<int>('age')` but the stored value is a `String`, you get `null` silently. Always use the correct type.

---

## Roadmap

- [x] Auto-derived / computed fields with dependency tracking
- [x] Typed factory constructors for all field types
- [x] Responsive multi-column grid layout (mobile-first, auto row-packing)
- [ ] Camera support for image fields
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
