import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rj_form_engine/rj_form_engine.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

List<FieldMeta> _lineItemsGroup({GroupConfig? config}) => [
      FieldMeta.group(
        key: 'items',
        label: 'Line Items',
        fields: [
          FieldMeta.text(key: 'name', label: 'Item', required: true),
          FieldMeta.number(key: 'qty', label: 'Qty'),
          FieldMeta.number(key: 'price', label: 'Price'),
        ],
        config: config ?? const GroupConfig(addButtonLabel: 'Add Item'),
      ),
    ];

String _firstRowId(FormController c, String groupKey) {
  final rows = c.rawGroupRows(groupKey)!;
  return FormController.rowIdOf(rows.first, 0);
}

void main() {
  group('FieldMeta.group', () {
    test('rejects nested groups', () {
      expect(
        () => FieldMeta.group(
          key: 'outer',
          label: 'Outer',
          fields: FieldMeta.group(
            key: 'inner',
            label: 'Inner',
            fields: [FieldMeta.text(key: 'x', label: 'X')],
          ).let((g) => [g]),
        ),
        throwsAssertionError,
      );
    });

    test('rejects section headers inside groups', () {
      expect(
        () => FieldMeta.group(
          key: 'items',
          label: 'Items',
          fields: [
            FieldMeta.section(key: 'sec', label: 'Sec'),
            FieldMeta.text(key: 'name', label: 'Name'),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('rejects keys containing dots or brackets', () {
      expect(
        () => FieldMeta.group(
          key: 'a.b',
          label: 'Bad',
          fields: [FieldMeta.text(key: 'x', label: 'X')],
        ),
        throwsAssertionError,
      );
      expect(
        () => FieldMeta.group(
          key: 'items',
          label: 'Items',
          fields: [FieldMeta.text(key: 'x.y', label: 'X')],
        ),
        throwsAssertionError,
      );
    });
  });

  group('RjErrorKey', () {
    test('parses composite group keys', () {
      final key = RjErrorKey.tryParse('items.row_5.name');
      expect(key, isNotNull);
      expect(key!.groupKey, 'items');
      expect(key.rowId, 'row_5');
      expect(key.subKey, 'name');
    });

    test('returns null for plain keys', () {
      expect(RjErrorKey.tryParse('email'), isNull);
    });
  });

  group('FormController group rows', () {
    late FormController controller;
    late List<FieldMeta> fields;

    setUp(() {
      controller = FormController();
      fields = _lineItemsGroup();
    });

    tearDown(() {
      controller.dispose();
    });

    test('ensureGroupRows seeds minRows with a row', () {
      controller.ensureGroupRows('items', fields);
      expect(controller.rawGroupRows('items')!.length, 1);
    });

    test('addGroupRow appends rows and respects maxRows', () {
      fields = _lineItemsGroup(
        config: const GroupConfig(addButtonLabel: 'Add', maxRows: 2),
      );
      controller.ensureGroupRows('items', fields);
      controller.addGroupRow('items', fields);
      expect(controller.rawGroupRows('items')!.length, 2);

      // At the max — no-op.
      controller.addGroupRow('items', fields);
      expect(controller.rawGroupRows('items')!.length, 2);
    });

    test('removeGroupRow respects minRows', () {
      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');
      controller.removeGroupRow('items', rowId, fields);
      expect(controller.rawGroupRows('items')!.length, 1);
    });

    test('setGroupRowValue stores values and strips __rowId from output', () {
      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');
      controller.setGroupRowValue('items', rowId, 'name', 'Milk', fields);

      final result = controller.toResult();
      final itemMaps = (result.values['items'] as List)
          .map((e) => e as Map)
          .toList();
      expect(itemMaps.first['name'], 'Milk');
      expect(itemMaps.first.containsKey('__rowId'), false);

      final publicItems = controller.values['items'] as List;
      expect((publicItems.first as Map).containsKey('__rowId'), false);

      // Raw internal state keeps the id.
      expect(
        (controller.rawState['items'] as List).first,
        containsPair('__rowId', rowId),
      );
    });

    test('public values are a deep copy — mutations cannot corrupt state', () {
      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');
      controller.setGroupRowValue('items', rowId, 'name', 'Milk', fields);

      (controller.values['items'] as List)[0]['name'] = 'HACKED!';

      expect(
        (controller.rawState['items'] as List)[0]['name'],
        'Milk',
      );
    });

    test('row ids are stable and never index-based', () {
      controller.ensureGroupRows('items', fields);
      controller.addGroupRow('items', fields);
      final rows = controller.rawGroupRows('items')!;
      final id0 = FormController.rowIdOf(rows[0], 0);
      final id1 = FormController.rowIdOf(rows[1], 1);
      expect(id0, isNot(id1));
      expect(id0, startsWith('row_items_'));
    });
  });

  group('FormController group validation', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('required sub-field error uses composite key', () {
      final fields = _lineItemsGroup();
      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');

      expect(controller.validate(fields), false);
      expect(controller.errors['items.$rowId.name'], 'Item is required');
      // Index-based key must NOT be used.
      expect(controller.errors.containsKey('items.0.name'), false);
    });

    test('validating a filled row clears its error', () {
      final fields = _lineItemsGroup();
      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');

      controller.validate(fields);
      controller.setGroupRowValue('items', rowId, 'name', 'Milk', fields);
      expect(controller.validate(fields), true);
      expect(controller.errors, isEmpty);
    });

    test('hides row sub-fields via row-scoped dependency', () {
      final fields = [
        FieldMeta.group(
          key: 'details',
          label: 'Details',
          fields: [
            FieldMeta.toggle(key: 'has_note', label: 'Has note?'),
            FieldMeta.text(
              key: 'note',
              label: 'Note',
              required: true,
              dependency: FieldDependency(
                dependsOn: 'has_note',
                condition: (v) => v == true,
              ),
            ),
          ],
        ),
        FieldMeta.text(key: 'name', label: 'Name', required: true),
      ];

      controller.ensureGroupRows('details', fields);
      controller.setGroupRowValue('details', _firstRowId(controller, 'details'),
          'has_note', false, fields);

      expect(controller.validate(fields), false); // only 'name' fails
      expect(controller.errors.containsKey('details..'), false);
      expect(controller.errors.containsKey('name'), true);
    });
  });

  group('FormController group derivations', () {
    late FormController controller;
    late List<FieldMeta> fields;

    setUp(() {
      controller = FormController();
      fields = [
        FieldMeta.group(
          key: 'items',
          label: 'Line Items',
          fields: [
            FieldMeta.number(key: 'price', label: 'Price'),
            FieldMeta.number(key: 'qty', label: 'Qty'),
            FieldMeta.number(
              key: 'total',
              label: 'Total',
              derivation: FieldDerivation(
                derivesFrom: ['price', 'qty'],
                compute: (state) {
                  final p = (state['price'] as num?)?.toDouble() ?? 0;
                  final q = (state['qty'] as num?)?.toDouble() ?? 0;
                  return p * q;
                },
              ),
            ),
          ],
        ),
        FieldMeta.number(
          key: 'grandTotal',
          label: 'Grand Total',
          derivation: FieldDerivation(
            derivesFrom: ['items'],
            compute: (state) {
              final rows = state['items'] as List? ?? const [];
              var s = 0.0;
              for (final r in rows) {
                if (r is Map) {
                  s += (r['total'] as num?)?.toDouble() ?? 0;
                }
              }
              return s;
            },
          ),
        ),
      ];
    });

    tearDown(() {
      controller.dispose();
    });

    double rowTotal(int index) {
      final rows = controller.rawGroupRows('items')!;
      return (rows[index]['total'] as num?)?.toDouble() ?? 0;
    }

    test('row derivation recomputes per row', () {
      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');
      controller.setGroupRowValue('items', rowId, 'price', 10, fields);
      controller.setGroupRowValue('items', rowId, 'qty', 3, fields);

      expect(rowTotal(0), 30);
      expect(controller.toResult().values['grandTotal'], 30);
    });

    test('grand total updates across added rows', () {
      controller.ensureGroupRows('items', fields);
      final id0 = _firstRowId(controller, 'items');
      controller.setGroupRowValue('items', id0, 'price', 10, fields);
      controller.setGroupRowValue('items', id0, 'qty', 3, fields);

      controller.addGroupRow('items', fields);
      final rows = controller.rawGroupRows('items')!;
      final id1 = FormController.rowIdOf(rows[1], 1);
      controller.setGroupRowValue('items', id1, 'price', 5, fields);
      controller.setGroupRowValue('items', id1, 'qty', 2, fields);

      expect(rowTotal(0), 30);
      expect(rowTotal(1), 10);
      expect(controller.toResult().values['grandTotal'], 40);
    });

    test('row derivation sees root state via merged scope', () {
      fields = [
        FieldMeta.number(key: 'taxRate', label: 'Tax %'),
        FieldMeta.group(
          key: 'items',
          label: 'Line Items',
          fields: [
            FieldMeta.number(key: 'price', label: 'Price'),
            FieldMeta.number(key: 'qty', label: 'Qty'),
            FieldMeta.number(
              key: 'total',
              label: 'Total',
              derivation: FieldDerivation(
                derivesFrom: ['price', 'qty', 'taxRate'],
                compute: (state) {
                  final p = (state['price'] as num?)?.toDouble() ?? 0;
                  final q = (state['qty'] as num?)?.toDouble() ?? 0;
                  final tax = (state['taxRate'] as num?)?.toDouble() ?? 0;
                  return p * q * (1 + tax / 100);
                },
              ),
            ),
          ],
        ),
      ];

      controller.ensureGroupRows('items', fields);
      final rowId = _firstRowId(controller, 'items');
      controller.setValueWithDerivation('taxRate', 10, fields);
      controller.setGroupRowValue('items', rowId, 'price', 100, fields);
      controller.setGroupRowValue('items', rowId, 'qty', 2, fields);
      expect(rowTotal(0), moreOrLessEquals(220, epsilon: 1e-9));

      // Root change propagates into the row.
      controller.setValueWithDerivation('taxRate', 20, fields);
      expect(rowTotal(0), moreOrLessEquals(240, epsilon: 1e-9));
    });
  });

  group('FormController mid-list removal identity', () {
    test('values and errors stay attached to the right rows', () {
      final controller = FormController();
      addTearDown(controller.dispose);
      final fields = _lineItemsGroup();

      controller.ensureGroupRows('items', fields);
      controller.addGroupRow('items', fields);
      final rows = controller.rawGroupRows('items')!;
      final id0 = FormController.rowIdOf(rows[0], 0);
      final id1 = FormController.rowIdOf(rows[1], 1);

      // Row 0 left empty (validation error), row 1 filled.
      controller.setGroupRowValue('items', id1, 'name', 'Milk', fields);

      expect(controller.validate(fields), false);
      expect(controller.errors['items.$id0.name'], 'Item is required');

      // Remove the FILLED row. The empty row's error must survive, keyed by id.
      controller.removeGroupRow('items', id1, fields);
      expect(controller.rawGroupRows('items')!.length, 1);
      expect(controller.errors['items.$id0.name'], 'Item is required');
      expect(controller.errors.containsKey('items.$id1.name'), false);

      // Filling it clears the surviving error.
      controller.setGroupRowValue('items', id0, 'name', 'Eggs', fields);
      controller.clearError('items.$id0.name');
      expect(controller.validate(fields), true);
    });
  });

  group('RjForm group widget', () {
    testWidgets('renders group label, rows and add button', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(fields: _lineItemsGroup(), onSubmit: (_) async {}),
      ));
      await tester.pump();

      expect(find.text('Line Items'), findsOneWidget);
      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
      // minRows = 1 → no remove button on the only row.
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('add/remove rows working end-to-end', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(fields: _lineItemsGroup(), onSubmit: (_) async {}),
      ));
      await tester.pump();

      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(find.text('Row 2'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      expect(find.text('Row 2'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('viewOnly hides add/remove controls', (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(fields: _lineItemsGroup(), viewOnly: true, onSubmit: (_) async {}),
      ));
      await tester.pump();

      expect(find.text('Add Item'), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('edit mode prefills rows and submits a clean list',
        (tester) async {
      FormResult? captured;
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: _lineItemsGroup(),
          initialValues: const {
            'items': [
              {'name': 'Milk', 'qty': 2},
              {'name': 'Eggs', 'qty': 12},
            ],
          },
          onSubmit: (result) async {
            captured = result;
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Row 2'), findsOneWidget);

      await tester.ensureVisible(find.text('Submit'));
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      final items = (captured!.values['items'] as List)
          .map((e) => e as Map)
          .toList();
      expect(items.length, 2);
      expect(items[0]['name'], 'Milk');
      expect(items[1]['name'], 'Eggs');
      expect(items[0].containsKey('__rowId'), false);
    });

    testWidgets('onChanged reports composite keys for row edits',
        (tester) async {
      final changes = <MapEntry<String, dynamic>>[];
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: _lineItemsGroup(),
          onSubmit: (_) async {},
          onChanged: (key, value) => changes.add(MapEntry(key, value)),
        ),
      ));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pump();

      expect(changes.length, 1);
      expect(changes[0].key, startsWith('items.row_'));
      expect(changes[0].key, endsWith('.name'));
      expect(changes[0].value, 'Milk');
    });

    testWidgets('error summary shows row numbers for group errors',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RjForm(
          fields: _lineItemsGroup(),
          onSubmit: (_) async {},
          showErrorsSummary: true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.textContaining('Line Items — Row 1: Item is required'),
          findsOneWidget);
    });

    testWidgets('group participates in responsive grid spans',
        (tester) async {
      final fields = [
        FieldMeta.text(
          key: 'customer',
          label: 'Customer',
          layout: const RjLayout(md: RjSpan.full),
        ),
        ..._lineItemsGroup(),
      ];
      await tester.pumpWidget(_wrap(
        RjForm(fields: fields, onSubmit: (_) async {}),
      ));
      await tester.pump();

      expect(find.text('Line Items'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
    });
  });

  group('Group regressions', () {
    List<FieldMeta> optionalNameGroup({
      bool required = false,
      List<FieldValidator> validators = const [],
      int minRows = 1,
    }) =>
        [
          FieldMeta.group(
            key: 'items',
            label: 'Line Items',
            required: required,
            validators: validators,
            fields: [
              FieldMeta.text(key: 'name', label: 'Item'),
              FieldMeta.number(
                key: 'double',
                label: 'Double',
                derivation: FieldDerivation(
                  derivesFrom: ['name'],
                  compute: (s) => 0,
                ),
              ),
            ],
            config: GroupConfig(minRows: minRows),
          ),
        ];

    testWidgets('controller.clear() re-seeds minRows', (tester) async {
      final c = FormController();
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(RjForm(
        controller: c,
        fields: _lineItemsGroup(config: const GroupConfig(minRows: 2)),
        hideSubmitButton: true,
      )));
      await tester.pump();
      expect(find.text('Row 2'), findsOneWidget);

      c.clear();
      await tester.pump();

      expect(c.rawGroupRows('items')!.length, 2);
      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Row 2'), findsOneWidget);
    });

    testWidgets('autoClearOnSubmit keeps minRows', (tester) async {
      final c = FormController();
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(RjForm(
        controller: c,
        fields: optionalNameGroup(),
        onSubmit: (_) async {},
        autoClearOnSubmit: true,
      )));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(c.rawGroupRows('items')!.length, 1);
      expect(find.text('Row 1'), findsOneWidget);
    });

    test('required group fails when it has no rows', () {
      final c = FormController();
      addTearDown(c.dispose);
      c.setAll({'items': <Map<String, dynamic>>[]});
      expect(c.validate(optionalNameGroup(required: true)), false);
      expect(c.errors['items'], 'Line Items is required');
    });

    test('required group fails when it has only blank rows', () {
      final c = FormController();
      addTearDown(c.dispose);
      final fields = optionalNameGroup(required: true);
      c.ensureGroupRows('items', fields);
      c.recomputeAllDerivations(fields); // derived value alone is not input
      expect(c.validate(fields), false);
      expect(c.errors['items'], 'Line Items is required');
    });

    test('required group passes once a row has a value', () {
      final c = FormController();
      addTearDown(c.dispose);
      final fields = optionalNameGroup(required: true);
      c.ensureGroupRows('items', fields);
      final rowId = _firstRowId(c, 'items');
      c.setGroupRowValue('items', rowId, 'name', 'Milk', fields);
      expect(c.validate(fields), true);
    });

    test('group validators receive the clean row list', () {
      final c = FormController();
      addTearDown(c.dispose);
      List? seen;
      final fields = optionalNameGroup(validators: [
        (v) {
          seen = v as List;
          return (v).length < 2 ? 'Add at least 2 items' : null;
        },
      ]);
      c.ensureGroupRows('items', fields);
      expect(c.validate(fields), false);
      expect(c.errors['items'], 'Add at least 2 items');
      expect((seen!.first as Map).containsKey('__rowId'), false);
    });

    test('hidden group is not validated', () {
      final c = FormController();
      addTearDown(c.dispose);
      final fields = [
        FieldMeta.toggle(key: 'hasItems', label: 'Has items'),
        FieldMeta.group(
          key: 'items',
          label: 'Line Items',
          required: true,
          dependency: FieldDependency(
            dependsOn: 'hasItems',
            condition: (v) => v == true,
          ),
          fields: [FieldMeta.text(key: 'name', label: 'Item')],
        ),
      ];
      expect(c.validate(fields), true);
    });

    testWidgets('group-level error renders and clears on edit',
        (tester) async {
      await tester.pumpWidget(_wrap(RjForm(
        fields: optionalNameGroup(required: true),
        onSubmit: (_) async {},
      )));
      await tester.pump();
      await tester.tap(find.text('Submit'));
      await tester.pump();
      expect(find.text('Line Items is required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pump();
      expect(find.text('Line Items is required'), findsNothing);
    });

    test('removing or adding a row recomputes root roll-ups', () {
      final c = FormController();
      addTearDown(c.dispose);
      final fields = [
        FieldMeta.group(
          key: 'items',
          label: 'Items',
          fields: [FieldMeta.number(key: 'amt', label: 'Amt')],
        ),
        FieldMeta.number(
          key: 'total',
          label: 'Total',
          derivation: FieldDerivation(
            derivesFrom: ['items'],
            compute: (s) => (s['items'] as List? ?? const [])
                .fold<num>(0, (a, r) => a + ((r as Map)['amt'] as num? ?? 0)),
          ),
        ),
        FieldMeta.number(
          key: 'count',
          label: 'Count',
          derivation: FieldDerivation(
            derivesFrom: ['items'],
            compute: (s) => (s['items'] as List? ?? const []).length,
          ),
        ),
      ];
      c.ensureGroupRows('items', fields);
      c.addGroupRow('items', fields);
      expect(c.values['count'], 2);

      final rows = c.rawGroupRows('items')!;
      final id1 = FormController.rowIdOf(rows[0], 0);
      final id2 = FormController.rowIdOf(rows[1], 1);
      c.setGroupRowValue('items', id1, 'amt', 7.5, fields);
      c.setGroupRowValue('items', id2, 'amt', 8, fields);
      expect(c.values['total'], 15.5);

      c.removeGroupRow('items', id1, fields);
      expect(c.values['total'], 8);
      expect(c.values['count'], 1);
    });

    testWidgets('untouched form with a group is not dirty', (tester) async {
      final c = FormController();
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(RjForm(
        controller: c,
        fields: _lineItemsGroup(),
        hideSubmitButton: true,
      )));
      await tester.pump();
      expect(c.rawGroupRows('items')!.length, 1);
      expect(c.isDirty, false);

      await tester.enterText(find.byType(TextFormField).first, 'Milk');
      await tester.pump();
      expect(c.isDirty, true);
    });
  });
}

extension<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
