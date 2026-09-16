import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'cpp_editor_controller.dart';

/// A horizontal strip of frequently-needed C++ symbols, shown above the
/// software keyboard so common punctuation doesn't require switching
/// keyboard layers on a phone.
class EditorAccessoryBar extends StatelessWidget {
  final CppEditorController controller;
  final FocusNode focusNode;

  const EditorAccessoryBar({super.key, required this.controller, required this.focusNode});

  static const List<_AccessoryKey> _keys = [
    _AccessoryKey(label: '{ }', insert: '{}', cursorOffsetFromEnd: 1),
    _AccessoryKey(label: '( )', insert: '()', cursorOffsetFromEnd: 1),
    _AccessoryKey(label: '[ ]', insert: '[]', cursorOffsetFromEnd: 1),
    _AccessoryKey(label: ';', insert: ';'),
    _AccessoryKey(label: '=', insert: '='),
    _AccessoryKey(label: '<>', insert: '<>', cursorOffsetFromEnd: 1),
    _AccessoryKey(label: '#', insert: '#'),
    _AccessoryKey(label: '"', insert: '"'),
    _AccessoryKey(label: '::', insert: '::'),
    _AccessoryKey(label: '->', insert: '->'),
    _AccessoryKey(label: 'Tab', insert: '    '),
  ];

  void _insert(_AccessoryKey key) {
    final selection = controller.selection;
    final cursor = selection.isValid ? selection.start : controller.text.length;
    final newText = controller.text.replaceRange(cursor, selection.isValid ? selection.end : cursor, key.insert);
    final newCursor = cursor + key.insert.length - key.cursorOffsetFromEnd;
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      color: IdeColors.darkSurfaceAlt,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: _keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final key = _keys[index];
          return _AccessoryButton(label: key.label, onTap: () => _insert(key));
        },
      ),
    );
  }
}

class _AccessoryKey {
  final String label;
  final String insert;
  final int cursorOffsetFromEnd;

  const _AccessoryKey({required this.label, required this.insert, this.cursorOffsetFromEnd = 0});
}

class _AccessoryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AccessoryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: IdeColors.darkSurface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTheme.editorFontFamily,
              fontSize: 14,
              color: IdeColors.darkTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
