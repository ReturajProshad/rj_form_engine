import 'package:flutter_test/flutter_test.dart';
import 'package:rj_form_engine/rj_form_engine.dart';

void main() {
  group('RjSpan and RjLayout', () {
    test('RjSpan enum has expected values', () {
      expect(RjSpan.full, isNotNull);
      expect(RjSpan.half, isNotNull);
      expect(RjSpan.third, isNotNull);
      expect(RjSpan.quarter, isNotNull);
    });

    test('RjLayout defaults to full width', () {
      final layout = RjLayout();
      expect(layout.md, RjSpan.full);
      expect(layout.lg, isNull);
    });

    test('RjLayout can be configured with md and lg', () {
      final layout = RjLayout(
        md: RjSpan.half,
        lg: RjSpan.third,
      );
      expect(layout.md, RjSpan.half);
      expect(layout.lg, RjSpan.third);
    });
  });

  group('RjResponsive.resolveSpan', () {
    test('returns 12 for null layout (full-width default)', () {
      expect(RjResponsive.resolveSpan(null, 1024), 12);
      expect(RjResponsive.resolveSpan(null, 500), 12);
    });

    test('returns 12 for phone width regardless of layout', () {
      final layout = RjLayout(md: RjSpan.half);
      expect(RjResponsive.resolveSpan(layout, 400), 12); // phone
    });

    test('resolves span correctly on tablet (md)', () {
      // phone width (< 480)
      expect(
        RjResponsive.resolveSpan(RjLayout(md: RjSpan.half), 400),
        12,
      );

      // tablet width (≥ 768)
      expect(
        RjResponsive.resolveSpan(RjLayout(md: RjSpan.half), 800),
        6,
      );
      expect(
        RjResponsive.resolveSpan(RjLayout(md: RjSpan.third), 800),
        4,
      );
      expect(
        RjResponsive.resolveSpan(RjLayout(md: RjSpan.quarter), 800),
        3,
      );
      expect(
        RjResponsive.resolveSpan(RjLayout(md: RjSpan.full), 800),
        12,
      );
    });

    test('uses lg on desktop, falls back to md if lg is null', () {
      // desktop width (≥ 1024)
      const desktopWidth = 1200.0;

      // With lg specified
      expect(
        RjResponsive.resolveSpan(
          RjLayout(md: RjSpan.half, lg: RjSpan.third),
          desktopWidth,
        ),
        4, // lg = third = 4 cols
      );

      // Without lg specified (falls back to md)
      expect(
        RjResponsive.resolveSpan(
          RjLayout(md: RjSpan.half, lg: null),
          desktopWidth,
        ),
        6, // md = half = 6 cols
      );
    });

    test('span values map to correct column counts', () {
      const width = 800.0;
      final fullLayout = RjLayout(md: RjSpan.full);
      final halfLayout = RjLayout(md: RjSpan.half);
      final thirdLayout = RjLayout(md: RjSpan.third);
      final quarterLayout = RjLayout(md: RjSpan.quarter);

      expect(RjResponsive.resolveSpan(fullLayout, width), 12);
      expect(RjResponsive.resolveSpan(halfLayout, width), 6);
      expect(RjResponsive.resolveSpan(thirdLayout, width), 4);
      expect(RjResponsive.resolveSpan(quarterLayout, width), 3);
    });
  });

  group('FieldMeta with layout', () {
    test('FieldMeta.text accepts layout parameter', () {
      final field = FieldMeta.text(
        key: 'name',
        label: 'Name',
        layout: RjLayout(md: RjSpan.half),
      );
      expect(field.layout, isNotNull);
      expect(field.layout?.md, RjSpan.half);
    });

    test('FieldMeta defaults to null layout (backward compat)', () {
      final field = FieldMeta.text(
        key: 'name',
        label: 'Name',
      );
      expect(field.layout, isNull);
    });

    test('all field factories support layout parameter', () {
      expect(
        FieldMeta.number(
          key: 'age',
          label: 'Age',
          layout: RjLayout(md: RjSpan.quarter),
        ).layout,
        isNotNull,
      );

      expect(
        FieldMeta.date(
          key: 'dob',
          label: 'DOB',
          layout: RjLayout(md: RjSpan.half),
        ).layout,
        isNotNull,
      );

      expect(
        FieldMeta.dropdown(
          key: 'country',
          label: 'Country',
          layout: RjLayout(md: RjSpan.third),
        ).layout,
        isNotNull,
      );

      expect(
        FieldMeta.searchableDropdown(
          key: 'skill',
          label: 'Skill',
          layout: RjLayout(md: RjSpan.half),
        ).layout,
        isNotNull,
      );
    });

    test('copyWith preserves layout', () {
      final layout = RjLayout(md: RjSpan.half);
      final field = FieldMeta.text(
        key: 'name',
        label: 'Name',
        layout: layout,
      );

      final copied = field.copyWith(required: true);
      expect(copied.layout, layout);
    });

    test('copyWith can override layout', () {
      final oldLayout = RjLayout(md: RjSpan.half);
      final newLayout = RjLayout(md: RjSpan.third);

      final field = FieldMeta.text(
        key: 'name',
        label: 'Name',
        layout: oldLayout,
      );

      final copied = field.copyWith(layout: newLayout);
      expect(copied.layout, newLayout);
    });
  });
}
