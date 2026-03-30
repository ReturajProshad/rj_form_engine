import 'package:flutter/material.dart';
import 'package:rj_form_engine/rj_form_engine.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rj_form_engine Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const ExamplePage(),
    );
  }
}

// ─── Simulated API calls ─────────────────────────────────────────────────────

Future<List<DropdownItem>> fetchCountries([dynamic _]) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    DropdownItem(id: 'bd', label: 'Bangladesh'),
    DropdownItem(id: 'in', label: 'India'),
    DropdownItem(id: 'us', label: 'United States'),
  ];
}

Future<List<DropdownItem>> fetchCities([dynamic parentValue]) async {
  await Future.delayed(const Duration(milliseconds: 400));
  final map = {
    'bd': [
      DropdownItem(id: 'dhaka', label: 'Dhaka'),
      DropdownItem(id: 'ctg', label: 'Chittagong'),
    ],
    'in': [
      DropdownItem(id: 'mum', label: 'Mumbai'),
      DropdownItem(id: 'del', label: 'Delhi'),
    ],
    'us': [
      DropdownItem(id: 'nyc', label: 'New York'),
      DropdownItem(id: 'la', label: 'Los Angeles'),
    ],
  };
  return map[parentValue] ?? [];
}

// ─── Field Definitions ───────────────────────────────────────────────────────

final _fields = [
  FieldMeta(
    key: 'full_name',
    label: 'Full Name',
    type: FieldType.text,
    required: true,
    hint: 'Enter your full name',
    validators: [
      (v) => (v is String && v.trim().length < 3) ? 'Name too short' : null,
    ],
  ),
  FieldMeta(
    key: 'age',
    label: 'Age',
    type: FieldType.number,
    required: true,
    validators: [
      (v) => (v is num && v < 0) ? 'Age cannot be negative' : null,
    ],
  ),
  FieldMeta(
    key: 'dob',
    label: 'Date of Birth',
    type: FieldType.date,
    lastDate: DateTime.now(),
    firstDate: DateTime(1900),
  ),
  FieldMeta(
    key: 'bio',
    label: 'Bio',
    type: FieldType.textArea,
    hint: 'Write something about yourself...',
  ),
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
    required: true,
    dependsOn: 'country',
    dropdownSource: DropdownSource.async(fetchCities),
    dependency: FieldDependency(dependsOn: 'country'),
  ),
  FieldMeta(
    key: 'status',
    label: 'Status',
    type: FieldType.dropdown,
    dropdownSource: DropdownSource.static([
      DropdownItem(id: 'active', label: 'Active'),
      DropdownItem(id: 'inactive', label: 'Inactive'),
    ]),
  ),
  FieldMeta(
    key: 'avatar',
    label: 'Profile Photo',
    type: FieldType.image,
    maxImages: 2,
  ),
  // Custom field example
  FieldMeta.custom(
    key: 'agree',
    label: 'Terms',
    required: true,
    validators: [
      (v) => (v != true) ? 'You must agree to the terms' : null,
    ],
    builder: (context, value, onChanged, errorText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: value == true,
            onChanged: (v) => onChanged(v),
            title: const Text('I agree to the Terms & Conditions'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    },
  ),
];

// ─── Example Page ────────────────────────────────────────────────────────────

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  final _controller = FormController();
  FormResult? _lastResult;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('rj_form_engine example'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RjForm(
              fields: _fields,
              controller: _controller,
              theme: const RjFormTheme(
                primaryColor: Color(0xFF2563EB),
                fieldSpacing: 20,
              ),
              submitLabel: 'Save Profile',
              onSubmit: (result) async {
                // Simulate network call
                await Future.delayed(const Duration(seconds: 1));
                setState(() => _lastResult = result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Form submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

            // Show submitted values
            if (_lastResult != null) ...[
              const Divider(height: 40),
              const Text(
                'Submitted Values:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ..._lastResult!.values.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${e.key}: ${e.value}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
