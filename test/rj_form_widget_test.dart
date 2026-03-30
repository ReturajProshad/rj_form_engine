import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rj_form_engine/rj_form_engine.dart';

// Helpers
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

final _textField = FieldMeta(key: 'name', label: 'Full Name', type: FieldType.text, required: true);
final _numberField = FieldMeta(key: 'age', label: 'Age', type: FieldType.number);
final _textAreaField = FieldMeta(key: 'bio', label: 'Bio', type: FieldType.textArea);
final _dateField = FieldMeta(key: 'dob', label: 'Date of Birth', type: FieldType.date);
final _staticDropdown = FieldMeta(
  key: 'status',
  label: 'Status',
  type: FieldType.dropdown,
  dropdownSource: DropdownSource.static([
    DropdownItem(id: 'active', label: 'Active'),
    DropdownItem(id: 'inactive', label: 'Inactive'),
  ]),
);

void main() {
  group('RjForm widget', () {
    testWidgets('renders all field labels', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField, _numberField, _textAreaField],
          onSubmit: (_) async {},
        ),
      ));
      await tester.pump();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Bio'), findsOneWidget);
    });

    testWidgets('renders submit button with correct label', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          submitLabel: 'Save Profile',
          onSubmit: (_) async {},
        ),
      ));
      await tester.pump();

      expect(find.text('Save Profile'), findsOneWidget);
    });

    testWidgets('hides submit button when hideSubmitButton is true', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          hideSubmitButton: true,
          onSubmit: (_) async {},
        ),
      ));
      await tester.pump();

      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('shows validation error when required field is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          onSubmit: (_) async {},
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Full Name is required'), findsOneWidget);
    });

    testWidgets('does not show error when required field has value', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          onSubmit: (_) async {},
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'John Doe');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name is required'), findsNothing);
    });

    testWidgets('calls onSubmit with correct values', (tester) async {
      FormResult? captured;

      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          onSubmit: (result) async {
            captured = result;
          },
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Jane');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.values['name'], 'Jane');
    });

    testWidgets('pre-fills initialValues', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          initialValues: {'name': 'Prefilled'},
          onSubmit: (_) async {},
        ),
      ));
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(field.controller?.text, 'Prefilled');
    });

    testWidgets('renders static dropdown items', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_staticDropdown],
          onSubmit: (_) async {},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsWidgets);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('hidden field is not rendered', (tester) async {
      final fields = [
        FieldMeta(key: 'type', label: 'Type', type: FieldType.text),
        FieldMeta(
          key: 'other',
          label: 'Other Detail',
          type: FieldType.text,
          dependency: FieldDependency(
            dependsOn: 'type',
            condition: (v) => v == 'other',
          ),
        ),
      ];

      await tester.pumpWidget(_wrap(
        RjForm(fields: fields, onSubmit: (_) async {}),
      ));
      await tester.pump();

      // 'other' field should not be visible yet
      expect(find.text('Other Detail'), findsNothing);
    });

    testWidgets('hidden field appears when condition is met', (tester) async {
      final fields = [
        FieldMeta(key: 'type', label: 'Type', type: FieldType.text),
        FieldMeta(
          key: 'other',
          label: 'Other Detail',
          type: FieldType.text,
          dependency: FieldDependency(
            dependsOn: 'type',
            condition: (v) => v == 'other',
          ),
        ),
      ];

      await tester.pumpWidget(_wrap(
        RjForm(fields: fields, onSubmit: (_) async {}),
      ));
      await tester.pump();

      // Type 'other' into the 'type' field
      await tester.enterText(find.byType(TextFormField).first, 'other');
      await tester.pump();

      // Now the conditional field should appear
      expect(find.text('Other Detail'), findsOneWidget);
    });

    testWidgets('viewOnly mode renders all fields as non-interactive', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField, _numberField],
          initialValues: {'name': 'John', 'age': 25},
          viewOnly: true,
          onSubmit: (_) async {},
        ),
      ));
      await tester.pumpAndSettle();

      // Submit button should not appear in view mode
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('external controller receives submitted values', (tester) async {
      final ctrl = FormController();
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_wrap(
        RjForm(
          fields: [_textField],
          controller: ctrl,
          onSubmit: (_) async {},
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'External');
      await tester.pump();

      expect(ctrl.values['name'], 'External');
    });

    testWidgets('custom field builder is called', (tester) async {
      var builderCalled = false;

      final customField = FieldMeta.custom(
        key: 'custom',
        label: 'Custom',
        builder: (context, value, onChanged, errorText) {
          builderCalled = true;
          return const Text('My Custom Widget');
        },
      );

      await tester.pumpWidget(_wrap(
        RjForm(fields: [customField], onSubmit: (_) async {}),
      ));
      await tester.pump();

      expect(builderCalled, true);
      expect(find.text('My Custom Widget'), findsOneWidget);
    });

    testWidgets('custom validator error is shown', (tester) async {
      final fields = [
        FieldMeta(
          key: 'email',
          label: 'Email',
          type: FieldType.text,
          validators: [(v) => (v is String && !v.contains('@')) ? 'Invalid email' : null],
        ),
      ];

      await tester.pumpWidget(_wrap(
        RjForm(fields: fields, onSubmit: (_) async {}),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
    });
  });
}
