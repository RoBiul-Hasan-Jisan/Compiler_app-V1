import 'package:flutter/material.dart';

import 'cpp_syntax_highlighter.dart';

/// A [TextEditingController] specialized for editing C++ source.
///
/// Responsibilities:
///  * Renders syntax-highlighted spans via [buildTextSpan].
///  * Auto-indents new lines to match the previous line's indentation,
///    adding one extra level after an opening brace.
///  * Auto-closes `(`, `[`, `{`, and `"` when typed.
///
/// Bracket-matching *highlighting* (as opposed to insertion) is computed by
/// [matchingBracketRange] and consumed by [CppCodeEditor] to draw the
/// highlight, since that requires layout information the controller
/// doesn't have.
class CppEditorController extends TextEditingController {
  double fontSize;
  bool syntaxHighlightingEnabled;
  int tabSize;
  bool autoIndentEnabled;

  static const Map<String, String> _autoClosePairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
  };

  CppEditorController({
    String? text,
    this.fontSize = 14,
    this.syntaxHighlightingEnabled = true,
    this.tabSize = 4,
    this.autoIndentEnabled = true,
  }) : super(text: text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    return CppSyntaxHighlighter.build(
      text,
      fontSize: fontSize,
      enabled: syntaxHighlightingEnabled,
    );
  }

  String get _indentUnit => ' ' * tabSize;

  /// Call from a [TextField.onChanged]-adjacent hook (see [handleKeyEvent])
  /// or directly wire via a custom [TextInputFormatter] if finer control is
  /// needed. Here we intercept via [RawKeyboardListener] in the widget and
  /// call this for the Enter key and bracket keys.
  void insertNewlineWithAutoIndent() {
    final selection = this.selection;
    if (!selection.isValid) return;

    final cursor = selection.start;
    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final currentLineStart = before.lastIndexOf('\n') + 1;
    final currentLine = before.substring(currentLineStart);
    final indentMatch = RegExp(r'^[ \t]*').firstMatch(currentLine);
    var indent = indentMatch?.group(0) ?? '';

    final trimmedLine = currentLine.trimRight();
    if (autoIndentEnabled && trimmedLine.endsWith('{')) {
      indent += _indentUnit;
    }

    // If the cursor sits between `{` and `}` on its own, also push the
    // closing brace onto a new, correctly-dedented line.
    final nextChar = after.isNotEmpty ? after[0] : '';
    if (autoIndentEnabled && trimmedLine.endsWith('{') && nextChar == '}') {
      final closingIndent = indentMatch?.group(0) ?? '';
      final insertion = '\n$indent\n$closingIndent';
      final newText = before + insertion + after;
      final newCursor = cursor + 1 + indent.length;
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
      return;
    }

    final insertion = '\n$indent';
    final newText = before + insertion + after;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + insertion.length),
    );
  }

  /// Handles auto-closing of brackets/quotes. Returns true if it handled
  /// the character itself (caller should not also insert it normally).
  bool handleAutoClose(String character) {
    final closing = _autoClosePairs[character];
    if (closing == null) return false;

    final selection = this.selection;
    if (!selection.isValid) return false;

    // If text is selected, wrap the selection instead of replacing it.
    if (!selection.isCollapsed) {
      final selected = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$character$selected$closing');
      value = TextEditingValue(
        text: newText,
        selection: TextSelection(baseOffset: selection.start + 1, extentOffset: selection.end + 1),
      );
      return true;
    }

    final cursor = selection.start;
    final newText = text.replaceRange(cursor, cursor, '$character$closing');
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + 1),
    );
    return true;
  }

  /// When typing a closing character right before an identical
  /// auto-inserted one, move past it instead of inserting a duplicate.
  bool handleSkipOverClosing(String character) {
    if (!_autoClosePairs.values.contains(character)) return false;
    final selection = this.selection;
    if (!selection.isValid || !selection.isCollapsed) return false;

    final cursor = selection.start;
    if (cursor < text.length && text[cursor] == character) {
      value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: cursor + 1));
      return true;
    }
    return false;
  }

  static const Map<String, String> openToClose = {'(': ')', '[': ']', '{': '}'};
  static const Map<String, String> closeToOpen = {')': '(', ']': '[', '}': '{'};

  /// Finds the offset of the bracket matching the one at [offset], if any.
  /// Returns null when there is no bracket at that position or no match.
  int? matchingBracketOffset(int offset) {
    if (offset < 0 || offset >= text.length) return null;
    final char = text[offset];

    if (openToClose.containsKey(char)) {
      final target = openToClose[char]!;
      var depth = 1;
      for (var i = offset + 1; i < text.length; i++) {
        if (text[i] == char) depth++;
        if (text[i] == target) depth--;
        if (depth == 0) return i;
      }
    } else if (closeToOpen.containsKey(char)) {
      final target = closeToOpen[char]!;
      var depth = 1;
      for (var i = offset - 1; i >= 0; i--) {
        if (text[i] == char) depth++;
        if (text[i] == target) depth--;
        if (depth == 0) return i;
      }
    }
    return null;
  }
}
