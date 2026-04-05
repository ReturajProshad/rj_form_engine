import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';
import '../../utils/rj_responsive.dart';

class RjImageField extends StatefulWidget {
  final FieldMeta field;
  final List<String> value;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(List<String> paths) onChanged;
  final void Function(String error)? onValidationError;
  final double width;

  const RjImageField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.errorText,
    this.onValidationError,
    this.width = 0,
  });

  @override
  State<RjImageField> createState() => _RjImageFieldState();
}

class _RjImageFieldState extends State<RjImageField> {
  final _picker = ImagePicker();

  Future<void> _pick() async {
    if (widget.value.length >= widget.field.maxImages) {
      _showError('Maximum ${widget.field.maxImages} image(s) allowed.');
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (picked == null) return;

    final file = File(picked.path);
    final size = await file.length();

    if (size > widget.field.maxImageSizeBytes) {
      final maxMb = (widget.field.maxImageSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      _showError('Image must be smaller than ${maxMb}MB.');
      return;
    }

    widget.onChanged([...widget.value, picked.path]);
  }

  void _showError(String message) {
    widget.onValidationError?.call(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _remove(int index) {
    final updated = List<String>.from(widget.value)..removeAt(index);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hasError = widget.errorText != null;
    final tileSize = RjResponsive.imageTileSize(widget.width);
    final gridSpacing = RjResponsive.imageGridSpacing(widget.width);
    final addTileLabelFontSize = RjResponsive.addTileLabelFontSize(widget.width);
    final addTileIconSize = RjResponsive.addTileIconSize(widget.width);
    final removeIconSz = RjResponsive.removeIconSize(widget.width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
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
              Text(
                ' *',
                style: TextStyle(color: theme.errorColor),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Image grid
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.fieldFillColor,
            borderRadius: theme.borderRadius,
            border: Border.all(
              color: hasError ? theme.errorColor : theme.borderColor,
              width: theme.borderWidth,
            ),
          ),
          child: Wrap(
            spacing: gridSpacing,
            runSpacing: gridSpacing,
            children: [
              // Existing images
              ...widget.value.asMap().entries.map(
                    (e) => _ImageTile(
                      path: e.value,
                      onRemove: () => _remove(e.key),
                      borderRadius: theme.borderRadius,
                      tileSize: tileSize,
                      removeIconSize: removeIconSz,
                    ),
                  ),

              // Add button (shown when below max)
              if (widget.value.length < widget.field.maxImages)
                _AddTile(
                  onTap: _pick,
                  primaryColor: theme.primaryColor,
                  borderColor: theme.borderColor,
                  borderRadius: theme.borderRadius,
                  tileSize: tileSize,
                  label: widget.value.isEmpty ? 'Add ${widget.field.label}' : 'Add more',
                  labelFontSize: addTileLabelFontSize,
                  iconSize: addTileIconSize,
                ),
            ],
          ),
        ),

        // Error text
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: theme.errorStyle ??
                  TextStyle(
                    color: theme.errorColor,
                    fontSize: RjResponsive.errorFontSize(widget.width),
                  ),
            ),
          ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final Color primaryColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final String label;
  final double tileSize;
  final double labelFontSize;
  final double iconSize;

  const _AddTile({
    required this.onTap,
    required this.primaryColor,
    required this.borderColor,
    required this.borderRadius,
    required this.label,
    this.tileSize = 90,
    this.labelFontSize = 10,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: SizedBox(
        width: tileSize,
        height: tileSize,
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.05),
            borderRadius: borderRadius,
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, color: primaryColor, size: iconSize),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final BorderRadius borderRadius;
  final double tileSize;
  final double removeIconSize;

  const _ImageTile({
    required this.path,
    required this.onRemove,
    required this.borderRadius,
    this.tileSize = 90,
    this.removeIconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: Image.file(
              File(path),
              width: tileSize,
              height: tileSize,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: removeIconSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
