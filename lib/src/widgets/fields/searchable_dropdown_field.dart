import 'package:flutter/material.dart';
import '../../models/dropdown_item.dart';
import '../../models/field_meta.dart';
import '../../theme/form_theme.dart';
import '../../utils/rj_responsive.dart';

class RjSearchableDropdownField extends StatefulWidget {
  final FieldMeta field;
  final String? value;
  final dynamic parentValue;
  final String? errorText;
  final RjFormTheme theme;
  final void Function(String? value, {String? label}) onChanged;
  final double width;

  const RjSearchableDropdownField({
    super.key,
    required this.field,
    required this.onChanged,
    required this.theme,
    this.value,
    this.parentValue,
    this.errorText,
    this.width = 0,
  });

  @override
  State<RjSearchableDropdownField> createState() =>
      _RjSearchableDropdownFieldState();
}

class _RjSearchableDropdownFieldState extends State<RjSearchableDropdownField> {
  late TextEditingController _searchController;
  late FocusNode _focusNode;
  List<DropdownItem> _allItems = [];
  List<DropdownItem> _filteredItems = [];
  bool _loading = false;
  String? _loadError;
  dynamic _lastParentValue;
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;
  final GlobalKey _fieldKey = GlobalKey();
  double _fieldWidth = 0;
  double _fieldHeight = 0;
  Offset _fieldGlobalOffset = Offset.zero;
  final LayerLink _layerLink = LayerLink();
  DropdownItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode();
    _lastParentValue = widget.parentValue;
    _focusNode.addListener(_handleFocusChange);
    _initializeSelectedItem();
    _load();
  }

  void _initializeSelectedItem() {
    if (widget.value != null && _allItems.isNotEmpty) {
      try {
        _selectedItem = _allItems.firstWhere((item) => item.id == widget.value);
        _searchController.text = _selectedItem!.label;
      } catch (_) {
        _selectedItem = null;
      }
    }
  }

  @override
  void didUpdateWidget(RjSearchableDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parentValue != _lastParentValue) {
      _lastParentValue = widget.parentValue;
      _selectedItem = null;
      _searchController.clear();
      _load();
    } else if (widget.value != oldWidget.value && !_isDropdownOpen) {
      _initializeSelectedItem();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _removeDropdown();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _openDropdown();
      // Clear the field when focused to allow typing
      if (_selectedItem != null) {
        _searchController.text = '';
        _filteredItems = List<DropdownItem>.from(_allItems);
        _overlayEntry?.markNeedsBuild();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus && _isDropdownOpen) {
          _removeDropdown();
          // Show selected label when focus is lost
          if (_selectedItem != null) {
            _searchController.text = _selectedItem!.label;
          }
        }
      });
    }
  }

  Future<void> _load() async {
    if (widget.field.dropdownSource == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await widget.field.dropdownSource!
          .resolve(parentValue: widget.parentValue?.toString());
      if (mounted) {
        setState(() {
          _allItems = items;
          _filteredItems = List<DropdownItem>.from(items);
          _loading = false;
          _initializeSelectedItem();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load ${widget.field.label}';
          _loading = false;
        });
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List<DropdownItem>.from(_allItems);
      } else {
        _filteredItems = _allItems
            .where((item) =>
                item.label.toLowerCase().contains(query.toLowerCase()) ||
                item.id.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });

    if (_isDropdownOpen) {
      _overlayEntry?.markNeedsBuild();
    } else if (query.isNotEmpty) {
      _openDropdown();
    }
  }

  void _updateFieldMetrics() {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final topLeft = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _fieldWidth = size.width;
        _fieldHeight = size.height;
        _fieldGlobalOffset = topLeft;
      });
    }
  }

  void _openDropdown() {
    if (_isDropdownOpen) return;
    _updateFieldMetrics();
    _isDropdownOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
    setState(() {});
  }

  void _removeDropdown() {
    if (!_isDropdownOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _selectItem(DropdownItem item) {
    setState(() {
      _selectedItem = item;
      _searchController.text = item.label;
    });
    widget.onChanged(item.id, label: item.label);
    _removeDropdown();
    FocusScope.of(context).unfocus();
  }

  OverlayEntry _createOverlayEntry() {
    final config = widget.field.searchableDropdownConfig;
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Background tap area to close dropdown
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeDropdown();
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            // The Dropdown
            Positioned(
              // 1. Position the container exactly where the Target is (Top-Left)
              left: _fieldGlobalOffset.dx,
              top: _fieldGlobalOffset.dy,
              width: _fieldWidth,
              child: CompositedTransformFollower(
                link: _layerLink,
                // 2. Use the offset to push the dropdown DOWN below the field
                offset: Offset(config.offsetX, _fieldHeight + config.offsetY),
                showWhenUnlinked: false,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: config.maxHeight),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.theme.fieldFillColor,
                        borderRadius: widget.theme.borderRadius,
                        border: Border.all(
                          color: widget.theme.borderColor,
                          width: widget.theme.borderWidth,
                        ),
                      ),
                      child: _buildList(config.maxHeight),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(double maxHeight) {
    if (_filteredItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'No items found',
          style: widget.theme.hintStyle ??
              const TextStyle(color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: widget.theme.borderColor.withAlpha(77),
        ),
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          final isSelected = _selectedItem?.id == item.id;
          return InkWell(
            onTap: () => _selectItem(item),
            child: Container(
              color: isSelected ? widget.theme.borderColor.withAlpha(51) : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: widget.theme.inputStyle ??
                          TextStyle(
                            color: const Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check,
                      color: widget.theme.primaryColor,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildShell(
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return _buildShell(
        child: Row(
          children: [
            Icon(Icons.error_outline, color: widget.theme.errorColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _loadError!,
                style: TextStyle(color: widget.theme.errorColor, fontSize: 12),
              ),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final isWaitingForParent = widget.field.dependency?.dependsOn != null &&
        widget.parentValue == null;

    // 1. Get the base decoration from the theme
    final baseDecoration = widget.theme.inputDecoration(
      label: widget.field.showLabel ? widget.field.label : null,
      hint: isWaitingForParent
          ? 'Select ${widget.field.dependency?.dependsOn} first'
          : widget.field.hint ?? 'Select or type',
      errorText: widget.errorText,
    );

    // 2. Create the Trailing Icon Button
    Widget trailingIcon = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Icon(
        _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
        // Try to use a color from your theme, or fallback to grey
        color: isWaitingForParent
            ? Colors.black.withValues(alpha: .5)
            : widget.theme.hintStyle?.color ?? Colors.black,
      ),
    );

    // 3. Merge the icon into the decoration
    final decorationWithIcon = baseDecoration.copyWith(
      suffixIcon: GestureDetector(
        onTap: isWaitingForParent
            ? null // Disable tap if waiting for parent
            : () {
                if (_isDropdownOpen) {
                  _removeDropdown();
                  _focusNode.unfocus();
                } else {
                  // Requesting focus triggers _handleFocusChange -> _openDropdown
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
        child: trailingIcon,
      ),
    );

    return PopScope(
      canPop: !_isDropdownOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isDropdownOpen) {
          _removeDropdown();
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: AbsorbPointer(
          absorbing: isWaitingForParent,
          child: Opacity(
            opacity: isWaitingForParent ? 0.5 : 1.0,
            child: Container(
              key: _fieldKey,
              child: TextFormField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _filterItems,
                // 4. Apply the updated decoration with the button
                decoration: decorationWithIcon,
                style: widget.theme.inputStyle ??
                    TextStyle(
                      fontSize: RjResponsive.inputFontSize(widget.width),
                      color: const Color(0xFF111827),
                    ),
                readOnly: isWaitingForParent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShell({required Widget child}) {
    return InputDecorator(
      decoration: widget.theme.inputDecoration(
        label: widget.field.showLabel ? widget.field.label : null,
        errorText: widget.errorText,
      ),
      child: child,
    );
  }
}
