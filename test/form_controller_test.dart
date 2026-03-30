import 'package:flutter_test/flutter_test.dart';
import 'package:rj_form_engine/rj_form_engine.dart';

void main() {
  group('FormController', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      controller.dispose();
    });

    // ─── Values ──────────────────────────────────────────────────────────────

    test('starts with empty values and errors', () {
      expect(controller.values, isEmpty);
      expect(controller.errors, isEmpty);
      expect(controller.isDirty, false);
    });

    test('setValue sets a single value and notifies', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setValue('name', 'John');

      expect(controller.values['name'], 'John');
      expect(notified, true);
    });

    test('setValue overwrites existing value', () {
      controller.setValue('name', 'John');
      controller.setValue('name', 'Jane');
      expect(controller.values['name'], 'Jane');
    });

    test('setAll replaces all values', () {
      controller.setValue('old_key', 'old_value');
      controller.setAll({'name': 'John', 'age': 30});

      expect(controller.values.containsKey('old_key'), false);
      expect(controller.values['name'], 'John');
      expect(controller.values['age'], 30);
    });

    test('removeValue removes a single key', () {
      controller.setAll({'name': 'John', 'age': 30});
      controller.removeValue('age');

      expect(controller.values.containsKey('age'), false);
      expect(controller.values['name'], 'John');
    });

    test('clear resets values and errors', () {
      controller.setValue('name', 'John');
      controller.setError('name', 'Error');
      controller.clear();

      expect(controller.values, isEmpty);
      expect(controller.errors, isEmpty);
      expect(controller.isDirty, false);
    });

    test('values map is unmodifiable', () {
      controller.setValue('name', 'John');
      expect(
        () => controller.values['hack'] = 'bad',
        throwsUnsupportedError,
      );
    });

    // ─── Errors ──────────────────────────────────────────────────────────────

    test('setError sets an error', () {
      controller.setError('name', 'Required');
      expect(controller.errors['name'], 'Required');
    });

    test('clearError removes a single error', () {
      controller.setError('name', 'Required');
      controller.setError('email', 'Invalid');
      controller.clearError('name');

      expect(controller.errors.containsKey('name'), false);
      expect(controller.errors['email'], 'Invalid');
    });

    test('clearErrors removes all errors', () {
      controller.setError('name', 'Required');
      controller.setError('email', 'Invalid');
      controller.clearErrors();

      expect(controller.errors, isEmpty);
    });

    // ─── Validation ──────────────────────────────────────────────────────────

    test('validate returns true when all required fields are filled', () {
      final fields = [
        FieldMeta(key: 'name', label: 'Name', type: FieldType.text, required: true),
      ];
      controller.setValue('name', 'John');

      expect(controller.validate(fields), true);
      expect(controller.errors, isEmpty);
    });

    test('validate returns false and sets error for empty required field', () {
      final fields = [
        FieldMeta(key: 'name', label: 'Name', type: FieldType.text, required: true),
      ];

      expect(controller.validate(fields), false);
      expect(controller.errors['name'], 'Name is required');
    });

    test('validate treats whitespace-only string as empty', () {
      final fields = [
        FieldMeta(key: 'name', label: 'Name', type: FieldType.text, required: true),
      ];
      controller.setValue('name', '   ');

      expect(controller.validate(fields), false);
      expect(controller.errors.containsKey('name'), true);
    });

    test('validate runs custom validators', () {
      final fields = [
        FieldMeta(
          key: 'age',
          label: 'Age',
          type: FieldType.number,
          validators: [(v) => (v is num && v < 0) ? 'Age must be positive' : null],
        ),
      ];
      controller.setValue('age', -5);

      expect(controller.validate(fields), false);
      expect(controller.errors['age'], 'Age must be positive');
    });

    test('validate skips hidden fields', () {
      final fields = [
        FieldMeta(key: 'type', label: 'Type', type: FieldType.text, required: true),
        FieldMeta(
          key: 'other',
          label: 'Other',
          type: FieldType.text,
          required: true,
          dependency: FieldDependency(
            dependsOn: 'type',
            condition: (v) => v == 'other',
          ),
        ),
      ];
      controller.setValue('type', 'standard'); // 'other' field is hidden

      expect(controller.validate(fields), true);
      expect(controller.errors.containsKey('other'), false);
    });

    test('validate treats empty list as empty for required image field', () {
      final fields = [
        FieldMeta(key: 'photo', label: 'Photo', type: FieldType.image, required: true),
      ];
      controller.setValue('photo', <String>[]);

      expect(controller.validate(fields), false);
      expect(controller.errors['photo'], 'Photo is required');
    });

    test('validate clears previous errors before re-validating', () {
      final fields = [
        FieldMeta(key: 'name', label: 'Name', type: FieldType.text, required: true),
      ];

      controller.validate(fields); // sets error
      expect(controller.errors.containsKey('name'), true);

      controller.setValue('name', 'John');
      controller.validate(fields); // should clear error
      expect(controller.errors.containsKey('name'), false);
    });

    // ─── Cascading ───────────────────────────────────────────────────────────

    test('setValueAndClearDependents clears direct child', () {
      final fields = [
        FieldMeta(key: 'country', label: 'Country', type: FieldType.dropdown),
        FieldMeta(
          key: 'city',
          label: 'City',
          type: FieldType.dropdown,
          dependency: FieldDependency(dependsOn: 'country'),
        ),
      ];

      controller.setValue('country', 'bd');
      controller.setValue('city', 'dhaka');

      controller.setValueAndClearDependents('country', 'in', fields);

      expect(controller.values['country'], 'in');
      expect(controller.values.containsKey('city'), false);
    });

    test('setValueAndClearDependents clears nested chain', () {
      final fields = [
        FieldMeta(key: 'country', label: 'Country', type: FieldType.dropdown),
        FieldMeta(
          key: 'division',
          label: 'Division',
          type: FieldType.dropdown,
          dependency: FieldDependency(dependsOn: 'country'),
        ),
        FieldMeta(
          key: 'district',
          label: 'District',
          type: FieldType.dropdown,
          dependency: FieldDependency(dependsOn: 'division'),
        ),
      ];

      controller.setValue('country', 'bd');
      controller.setValue('division', 'dhaka_div');
      controller.setValue('district', 'dhaka_dist');

      controller.setValueAndClearDependents('country', 'in', fields);

      expect(controller.values['country'], 'in');
      expect(controller.values.containsKey('division'), false);
      expect(controller.values.containsKey('district'), false);
    });

    // ─── FormResult ──────────────────────────────────────────────────────────

    test('toResult returns FormResult with current values', () {
      controller.setAll({'name': 'John', 'age': 30});
      final result = controller.toResult();

      expect(result.values['name'], 'John');
      expect(result.values['age'], 30);
    });

    test('FormResult.get returns typed value', () {
      controller.setValue('name', 'John');
      final result = controller.toResult();

      expect(result.get<String>('name'), 'John');
      expect(result.get<int>('name'), null); // wrong type returns null
    });
  });

  // ─── FieldDependency ─────────────────────────────────────────────────────

  group('FieldDependency', () {
    test('isVisible returns true when parent has any value (no condition)', () {
      final dep = FieldDependency(dependsOn: 'country');
      expect(dep.isVisible({'country': 'bd'}), true);
      expect(dep.isVisible({'country': null}), false);
      expect(dep.isVisible({}), false);
    });

    test('isVisible uses condition when provided', () {
      final dep = FieldDependency(
        dependsOn: 'type',
        condition: (v) => v == 'other',
      );

      expect(dep.isVisible({'type': 'other'}), true);
      expect(dep.isVisible({'type': 'standard'}), false);
      expect(dep.isVisible({}), false);
    });
  });

  // ─── DropdownSource ──────────────────────────────────────────────────────

  group('DropdownSource', () {
    test('static source resolves immediately', () async {
      final items = [
        DropdownItem(id: 'a', label: 'Option A'),
        DropdownItem(id: 'b', label: 'Option B'),
      ];
      final source = DropdownSource.static(items);
      final resolved = await source.resolve();

      expect(resolved.length, 2);
      expect(resolved.first.id, 'a');
    });

    test('async source resolves with loader', () async {
      final source = DropdownSource.async(([parentValue]) async {
        return [DropdownItem(id: 'x', label: 'X')];
      });

      final resolved = await source.resolve();
      expect(resolved.first.id, 'x');
    });

    test('async source receives parentValue for cascading', () async {
      dynamic received;
      final source = DropdownSource.async(([parentValue]) async {
        received = parentValue;
        return [];
      });

      await source.resolve('bd');
      expect(received, 'bd');
    });
  });

  // ─── DropdownItem ────────────────────────────────────────────────────────

  group('DropdownItem', () {
    test('equality is based on id', () {
      final a = DropdownItem(id: 'x', label: 'X');
      final b = DropdownItem(id: 'x', label: 'Different label');
      expect(a == b, true);
    });

    test('different ids are not equal', () {
      final a = DropdownItem(id: 'x', label: 'X');
      final b = DropdownItem(id: 'y', label: 'X');
      expect(a == b, false);
    });
  });
}
