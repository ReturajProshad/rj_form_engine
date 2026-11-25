import 'package:flutter/material.dart';
import '../models/field_meta.dart';
import '../theme/form_theme.dart';
import 'rj_responsive.dart';

/// Packs [fields] into a responsive 12-column grid (mobile-first), same rules
/// the top-level form uses:
///
/// - Phone (<768px): every field forced full-width.
/// - Tablet/desktop: each field's [RjLayout] span is respected.
/// - Consecutive fields auto-group into rows; a field wraps to a new row when
///   it would exceed 12 columns.
/// - [FieldType.section] breaks the current row and renders a divider.
///
/// Shared by the top-level [RjForm] and repeatable group rows.
List<Widget> buildResponsiveGrid({
  required double width,
  required RjFormTheme theme,
  required List<FieldMeta> fields,
  required Widget Function(FieldMeta field, double flex) fieldBuilder,
}) {
  const maxCols = 12;
  final widgets = <Widget>[];
  final currentRow = <(FieldMeta field, int span)>[];
  int currentRowCols = 0;

  void flushRow() {
    if (currentRow.isEmpty) return;

    if (currentRow.length == 1 && currentRow.first.$2 == maxCols) {
      final (field, _) = currentRow.first;
      widgets.add(fieldBuilder(field, 1.0));
    } else {
      final rowChildren = <Widget>[];
      for (int i = 0; i < currentRow.length; i++) {
        final (field, span) = currentRow[i];
        rowChildren.add(
          Expanded(
            flex: span,
            child: fieldBuilder(field, span / maxCols),
          ),
        );
        if (i < currentRow.length - 1) {
          rowChildren.add(SizedBox(width: RjResponsive.fieldSpacing(width)));
        }
      }
      widgets.add(IntrinsicHeight(child: Row(children: rowChildren)));
    }

    currentRow.clear();
    currentRowCols = 0;
  }

  for (final field in fields) {
    if (field.type == FieldType.section) {
      flushRow();
      widgets.add(buildSectionDivider(field, theme, width));
      continue;
    }

    final span = RjResponsive.resolveSpan(field.layout, width);
    if (currentRowCols + span > maxCols && currentRow.isNotEmpty) {
      flushRow();
    }
    currentRow.add((field, span));
    currentRowCols += span;
  }

  flushRow();
  return widgets;
}

/// Renders a [FieldType.section] as a centered, divided label header.
Widget buildSectionDivider(FieldMeta field, RjFormTheme theme, double width) {
  return Padding(
    padding: EdgeInsets.only(
      top: RjResponsive.fieldSpacing(width) * 1.5,
      bottom: RjResponsive.fieldSpacing(width) * 0.5,
    ),
    child: Row(
      children: [
        Expanded(child: Divider(color: theme.borderColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            field.label,
            style: theme.labelStyle ??
                TextStyle(
                  fontSize: RjResponsive.labelFontSize(width) + 2,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryColor,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        Expanded(child: Divider(color: theme.borderColor, thickness: 1)),
      ],
    ),
  );
}