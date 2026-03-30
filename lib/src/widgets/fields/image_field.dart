import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';

class RjImageField extends StatefulWidget {
  final FieldMeta field;
  final List<String> value; // list of file paths
  final String? errorText;
  final RjFormTheme theme;
  final void Function(List<String> paths) onChanged;

  const RjImageField({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    required this.theme,
    this.errorText,
  });

  @override
  State<RjImageField> createState() => _RjImageFieldState();
}

class _RjImageFieldState extends State<RjImageField> {
  final _picker = ImagePicker();

  Future<void> _pick() async {
    if (widget.value.length >= widget.field.maxImages) {
      _snack('Maximum ${widget.field.maxImages} image(s) allowed.');
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
      final maxMb =
          (widget.field.maxImageSizeBytes / (1024 * 1024)).toStringAsFixed(0);
      _snack('Image must be smaller than ${maxMb}MB.');
      return;
    }

    widget.onChanged([...widget.value, picked.path]);
  }

  void _remove(int index) {
    final updated = List<String>.from(widget.value)..removeAt(index);
    widget.onChanged(updated);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Text(
              widget.field.label,
              style: theme.labelStyle ??
                  const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
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
            spacing: 10,
            runSpacing: 10,
            children: [
              // Existing images
              ...widget.value.asMap().entries.map(
                    (e) => _ImageTile(
                      path: e.value,
                      onRemove: () => _remove(e.key),
                      borderRadius: theme.borderRadius,
                    ),
                  ),

              // Add button (shown when below max)
              if (widget.value.length < widget.field.maxImages)
                _AddTile(
                  onTap: _pick,
                  primaryColor: theme.primaryColor,
                  borderColor: theme.borderColor,
                  borderRadius: theme.borderRadius,
                  label: widget.value.isEmpty
                      ? 'Add ${widget.field.label}'
                      : 'Add more',
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
                  TextStyle(color: theme.errorColor, fontSize: 12),
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

  const _AddTile({
    required this.onTap,
    required this.primaryColor,
    required this.borderColor,
    required this.borderRadius,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: borderRadius,
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: primaryColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final BorderRadius borderRadius;

  const _ImageTile({
    required this.path,
    required this.onRemove,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: Image.file(
              File(path),
              width: 90,
              height: 90,
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
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
