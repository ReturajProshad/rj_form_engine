import 'package:flutter/material.dart';
import '../../models/field_meta.dart';
import '../../state/form_controller.dart';
import '../../theme/form_theme.dart';
import '../../utils/rj_grid.dart';
import '../../utils/rj_responsive.dart';
import 'field_widget.dart';

/// Renders a [FieldType.group]: a labeled block of fields repeated once per
/// row, with add/remove controls. Produces a `List<Map<String, dynamic>>`.
class RjGroupField extends StatefulWidget {
  final FieldMeta field;
  final double width;
  final FormController controller;
  final List<FieldMeta> formFields;
  final RjFormTheme theme;
  final bool viewOnly;
  final void Function(String key, dynamic value)? onChanged;

  const RjGroupField({
    super.key,
    required this.field,
    this.width = 0,
    required this.controller,
    required this.formFields,
    required this.theme,
    this.viewOnly = false,
    this.onChanged,
  });

  @override
  State<RjGroupField> createState() => _RjGroupFieldState();
}

class _RjGroupFieldState extends State<RjGroupField> {
  dynamic _lastList;
  String _lastErrorSig = '';
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed minRows / normalize ids before the first build.
    widget.controller.ensureGroupRows(widget.field.key, widget.formFields);
    if (!_subscribed) {
      _subscribed = true;
      widget.controller.addListener(_onControllerChanged);
      _lastList = widget.controller.rawValue(widget.field.key);
      _lastErrorSig = _errorSignature();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // clear() / setAll() can wipe the rows; re-seed minRows (and missing
    // row ids) so the group never drops below its configured minimum.
    widget.controller.ensureGroupRows(widget.field.key, widget.formFields);
    final list = widget.controller.rawValue(widget.field.key);
    final errSig = _errorSignature();
    if (list != _lastList || errSig != _lastErrorSig) {
      setState(() {
        _lastList = list;
        _lastErrorSig = errSig;
      });
    }
  }

  String _errorSignature() {
    final prefix = '${widget.field.key}.';
    final buf = StringBuffer();
    final own = widget.controller.rawError(widget.field.key);
    if (own != null) buf.write('=$own;');
    widget.controller.errors.forEach((k, v) {
      if (k.startsWith(prefix)) buf.write('$k=$v;');
    });
    return buf.toString();
  }

  void _addRow() {
    final c = widget.controller;
    final g = widget.field.key;
    c.addGroupRow(g, widget.formFields);
    c.clearError(g);
    widget.onChanged?.call(g, c.values[g] as List);
  }

  void _removeRow(String rowId) {
    final c = widget.controller;
    final g = widget.field.key;
    c.removeGroupRow(g, rowId, widget.formFields);
    widget.onChanged?.call(g, c.values[g] as List);
  }

  void _handleRowChange(
    FieldMeta sub,
    String rowId,
    String errorKey,
    dynamic value, {
    Map<String, dynamic>? extra,
  }) {
    final c = widget.controller;
    final g = widget.field.key;
    if (extra != null) {
      c.setGroupRowValueCascade(
        g,
        rowId,
        sub.key,
        value,
        widget.formFields,
        extraValues: extra,
      );
    } else {
      c.setGroupRowValue(g, rowId, sub.key, value, widget.formFields);
    }
    c.clearError(errorKey);
    if (c.rawError(g) != null) c.clearError(g);
    c.clearGroupDerivedFieldErrors(g, rowId, sub.key, widget.formFields);
    widget.onChanged?.call(errorKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final g = widget.field.key;
    final groupFields = widget.field.groupFields ?? const <FieldMeta>[];
    final cfg = widget.field.groupConfig;
    final rows = _lastList is List ? _lastList as List : const [];
    final isViewOnly = widget.viewOnly || widget.field.viewOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.field.showLabel) ...[
          Row(
            children: [
              Text(
                widget.field.label,
                style: theme.labelStyle ??
                    TextStyle(
                      fontSize: RjResponsive.labelFontSize(widget.width),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
              ),
              if (widget.field.required)
                Text(' *', style: TextStyle(color: theme.errorColor)),
            ],
          ),
          const SizedBox(height: 8),
        ],
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: RjResponsive.fieldSpacing(widget.width)),
          _buildRowCard(
            index: i,
            rowRaw: rows[i],
            rowsLength: rows.length,
            groupFields: groupFields,
            cfg: cfg,
            theme: theme,
            isViewOnly: isViewOnly,
            groupKey: g,
          ),
        ],
        if (rows.isNotEmpty) const SizedBox(height: 8),
        if (widget.controller.rawError(g) case final groupError?)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              groupError,
              style: theme.errorStyle ??
                  TextStyle(
                    color: theme.errorColor,
                    fontSize: RjResponsive.errorFontSize(widget.width),
                  ),
            ),
          ),
        if (!isViewOnly)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: cfg.maxRows != null && rows.length >= cfg.maxRows!
                  ? null
                  : _addRow,
              icon: const Icon(Icons.add, size: 18),
              label: Text(cfg.addButtonLabel),
            ),
          ),
      ],
    );
  }

  Widget _buildRowCard({
    required int index,
    required dynamic rowRaw,
    required int rowsLength,
    required List<FieldMeta> groupFields,
    required GroupConfig cfg,
    required RjFormTheme theme,
    required bool isViewOnly,
    required String groupKey,
  }) {
    final row = Map<String, dynamic>.from(rowRaw is Map ? rowRaw : {});
    final rowId = FormController.rowIdOf(rowRaw, index);
    final showRemove =
        !isViewOnly && cfg.showRemoveButton && rowsLength > cfg.minRows;

    return Container(
      key: ValueKey(rowId),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.fieldFillColor,
        borderRadius: theme.borderRadius,
        border: Border.all(color: theme.borderColor, width: theme.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Row ${index + 1}',
                style: theme.labelStyle ??
                    TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
              ),
              const Spacer(),
              if (showRemove)
                InkWell(
                  onTap: () => _removeRow(rowId),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: theme.errorColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final innerWidth = constraints.maxWidth;
              return Column(
                children: buildResponsiveGrid(
                  width: innerWidth,
                  theme: theme,
                  fields: groupFields,
                  fieldBuilder: (f, flex) =>
                      _buildRowField(f, row, rowId, groupKey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRowField(
    FieldMeta sub,
    Map<String, dynamic> row,
    String rowId,
    String groupKey,
  ) {
    final c = widget.controller;
    final isViewOnly = widget.viewOnly || widget.field.viewOnly;

    // Dependencies inside a row resolve against the merged {root, row} scope.
    final merged = {...c.rawState, ...row};
    if (sub.dependency != null && !sub.dependency!.isVisible(merged)) {
      return const SizedBox.shrink();
    }

    final eff = isViewOnly ? sub.copyWith(viewOnly: true) : sub;
    final errorKey = c.groupErrorKey(groupKey, rowId, sub.key);
    final error = c.rawError(errorKey);

    final fieldWidget = buildFieldWidget(
      context: context,
      field: eff,
      value: row[sub.key],
      error: error,
      theme: widget.theme,
      width: widget.width,
      parentValue: sub.dependency != null
          ? row[sub.dependency!.dependsOn] ??
              c.rawValue(sub.dependency!.dependsOn)
          : null,
      onChange: (v) => _handleRowChange(sub, rowId, errorKey, v),
      onCascadeChange: (v, {label}) {
        final extra = <String, dynamic>{};
        if (label != null) extra['${sub.key}Label'] = label;
        _handleRowChange(sub, rowId, errorKey, v, extra: extra);
      },
      onImageValidationError: (msg) => c.setError(errorKey, msg),
    );
    // Same vertical rhythm as root fields, so floating labels aren't clipped
    // by the field above. Derived sub-fields are read-only, like at root.
    return Padding(
      padding: EdgeInsets.only(
        bottom: RjResponsive.fieldSpacing(widget.width) * 0.75,
      ),
      child: AbsorbPointer(
        absorbing: sub.derivation != null,
        child: fieldWidget,
      ),
    );
  }
}
