import 'package:flutter/material.dart';
import 'package:rj_form_engine/rj_form_engine.dart';

void main() => runApp(const MyApp());

final messengerKey = GlobalKey<ScaffoldMessengerState>();

// ─── Mock async loaders ───────────────────────────────────────────────────────

Future<List<DropdownItem>> fetchCountries([_]) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    DropdownItem(id: 'bd', label: 'Bangladesh'),
    DropdownItem(id: 'us', label: 'United States'),
    DropdownItem(id: 'in', label: 'India'),
  ];
}

Future<List<DropdownItem>> fetchCities([dynamic country]) async {
  await Future.delayed(const Duration(milliseconds: 400));
  const map = {
    'bd': [
      {'id': 'dhaka', 'label': 'Dhaka'},
      {'id': 'ctg', 'label': 'Chattogram'},
    ],
    'us': [
      {'id': 'ny', 'label': 'New York'},
      {'id': 'sf', 'label': 'San Francisco'},
    ],
    'in': [
      {'id': 'mum', 'label': 'Mumbai'},
      {'id': 'del', 'label': 'Delhi'},
    ],
  };
  return (map[country] ?? [])
      .map((e) => DropdownItem(id: e['id']!, label: e['label']!))
      .toList();
}

// ─── Field definitions ────────────────────────────────────────────────────────

final _fields = [
  // ── Basic text ──
  FieldMeta(
    key: 'full_name',
    label: 'Full Name',
    type: FieldType.text,
    required: true,
    validators: [
      RjValidators.minLength(3),
      RjValidators.lettersOnly(),
    ],
  ),

  // ── Email with built-in validator ──
  FieldMeta(
    key: 'email',
    label: 'Email Address',
    type: FieldType.text,
    required: true,
    validators: [RjValidators.email()],
  ),

  // ── Phone with BD validator ──
  FieldMeta(
    key: 'phone',
    label: 'Mobile Number',
    type: FieldType.text,
    hint: '01XXXXXXXXX',
    validators: [RjValidators.bdPhone()],
  ),

  // ── Number with range ──
  FieldMeta(
    key: 'age',
    label: 'Age',
    type: FieldType.number,
    required: true,
    validators: [RjValidators.between(1, 120)],
  ),

  // ── Date ──
  FieldMeta(
    key: 'dob',
    label: 'Date of Birth',
    type: FieldType.date,
    required: true,
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
    validators: [RjValidators.pastDate()],
  ),

  // ── Time picker ──
  FieldMeta(
    key: 'preferred_time',
    label: 'Preferred Contact Time',
    type: FieldType.timePicker,
  ),

  // ── Dropdown cascade ──
  FieldMeta(
    key: 'country',
    label: 'Country',
    type: FieldType.dropdown,
    required: true,
    dropdownSource: DropdownSource.async(fetchCountries),
  ),
  FieldMeta(
    key: 'city',
    label: 'City',
    type: FieldType.dropdown,
    dependsOn: 'country',
    dependency: FieldDependency(
      dependsOn: 'country',
      condition: (v) => v != null,
    ),
    dropdownSource: DropdownSource.async(fetchCities),
  ),

  // ── Static dropdown ──
  FieldMeta(
    key: 'status',
    label: 'Account Status',
    type: FieldType.dropdown,
    dropdownSource: DropdownSource.static([
      DropdownItem(id: 'active', label: 'Active'),
      DropdownItem(id: 'inactive', label: 'Inactive'),
      DropdownItem(id: 'pending', label: 'Pending Review'),
    ]),
  ),

  // ── Radio ──
  FieldMeta(
    key: 'gender',
    label: 'Gender',
    type: FieldType.radio,
    required: true,
    options: [
      DropdownItem(id: 'male', label: 'Male'),
      DropdownItem(id: 'female', label: 'Female'),
      DropdownItem(id: 'other', label: 'Other / Prefer not to say'),
    ],
  ),

  // ── Chip (multi-select) ──
  FieldMeta(
    key: 'interests',
    label: 'Interests',
    type: FieldType.chip,
    required: true,
    validators: [RjValidators.minSelect(1, message: 'Pick at least one interest')],
    options: [
      DropdownItem(id: 'tech', label: 'Technology'),
      DropdownItem(id: 'agri', label: 'Agriculture'),
      DropdownItem(id: 'finance', label: 'Finance'),
      DropdownItem(id: 'health', label: 'Healthcare'),
      DropdownItem(id: 'edu', label: 'Education'),
      DropdownItem(id: 'erp', label: 'ERP Systems'),
    ],
  ),

  // ── Slider ──
  FieldMeta(
    key: 'experience_years',
    label: 'Years of Experience',
    type: FieldType.slider,
    sliderMin: 0,
    sliderMax: 30,
    sliderDivisions: 30,
    sliderLabelBuilder: (v) => '${v.toInt()} yrs',
  ),

  // ── Spinner ──
  FieldMeta(
    key: 'team_size',
    label: 'Team Size',
    type: FieldType.spinner,
    spinnerMin: 1,
    spinnerMax: 500,
    spinnerStep: 5,
    validators: [RjValidators.min(1)],
  ),

  // ── Toggle ──
  FieldMeta(
    key: 'notifications',
    label: 'Enable Notifications',
    type: FieldType.toggle,
    hint: 'Receive alerts for important updates',
  ),

  // ── Textarea ──
  FieldMeta(
    key: 'bio',
    label: 'Short Bio',
    type: FieldType.textArea,
    hint: 'Tell us about yourself...',
    validators: [RjValidators.maxLength(300)],
  ),

  // ── Image upload ──
  FieldMeta(
    key: 'profile_image',
    label: 'Profile Photo',
    type: FieldType.image,
    maxImages: 2,
  ),

  // ── Custom field — star rating ──
  FieldMeta.custom(
    key: 'rating',
    label: 'Satisfaction Rating',
    required: true,
    validators: [
      (v) => (v == null || v == 0) ? 'Please give a rating' : null,
    ],
    builder: (context, value, onChanged, errorText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Satisfaction Rating *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final selected = (value as int? ?? 0) > i;
              return IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => onChanged(i + 1),
              );
            }),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    },
  ),

  // ── Conditional field — shown only when country == 'bd' ──
  FieldMeta(
    key: 'nid',
    label: 'National ID (NID)',
    type: FieldType.text,
    hint: '10 or 17 digit NID number',
    dependency: FieldDependency(
      dependsOn: 'country',
      condition: (v) => v == 'bd',
    ),
    validators: [
      RjValidators.pattern(
        RegExp(r'^\d{10}$|^\d{17}$'),
        message: 'NID must be 10 or 17 digits',
      ),
    ],
  ),
];

// ─── App ─────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rj_form_engine showcase',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ShowcasePage(),
    );
  }
}

class ShowcasePage extends StatefulWidget {
  const ShowcasePage({super.key});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  final _controller = FormController();
  Map<String, dynamic>? _submitted;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('rj_form_engine'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset form',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.clear();
              setState(() => _submitted = null);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RjForm(
              fields: _fields,
              controller: _controller,
              submitLabel: 'Save Profile',
              theme: const RjFormTheme(
                primaryColor: Color(0xFF2563EB),
                fieldSpacing: 20,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              onSubmit: (result) async {
                await Future.delayed(const Duration(milliseconds: 800));
                setState(() => _submitted = result.values);
                messengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('✅ Form submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),

            // Show submitted values
            if (_submitted != null) ...[
              const Divider(height: 48),
              const Text(
                'Submitted Values',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._submitted!.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      // External submit via FAB
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.send),
        label: const Text('Submit via FAB'),
        onPressed: () {
          if (_controller.validate(_fields)) {
            final result = _controller.toResult();
            setState(() => _submitted = result.values);
            messengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('FAB submitted: ${result.values.length} fields')),
            );
          }
        },
      ),
    );
  }
}
