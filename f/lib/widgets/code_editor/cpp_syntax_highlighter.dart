import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tokenizes and colorizes C++ source for display inside the editor.
///
/// This is a regex-based lexer, not a full parser — it is deliberately
/// simple so it stays fast on large files, while still covering the token
/// classes a working C++ editor needs: keywords, types, functions, strings,
/// numbers, comments, preprocessor directives, operators, and classes.
class CppSyntaxHighlighter {
  CppSyntaxHighlighter._();

  static const Set<String> _keywords = {
    'alignas', 'alignof', 'and', 'and_eq', 'asm', 'auto', 'bitand', 'bitor',
    'break', 'case', 'catch', 'compl', 'const', 'consteval', 'constexpr',
    'constinit', 'const_cast', 'continue', 'co_await', 'co_return',
    'co_yield', 'decltype', 'default', 'delete', 'do', 'dynamic_cast',
    'else', 'enum', 'explicit', 'export', 'extern', 'false', 'final',
    'for', 'friend', 'goto', 'if', 'inline', 'mutable', 'namespace', 'new',
    'noexcept', 'not', 'not_eq', 'nullptr', 'operator', 'or', 'or_eq',
    'override', 'private', 'protected', 'public', 'register',
    'reinterpret_cast', 'return', 'sizeof', 'static', 'static_assert',
    'static_cast', 'struct', 'switch', 'template', 'this', 'thread_local',
    'throw', 'true', 'try', 'typedef', 'typeid', 'typename', 'union',
    'using', 'virtual', 'volatile', 'while', 'xor', 'xor_eq',
  };

  // mcpp's one builtin — colored distinctly (as a function) since it's
  // the language's primary I/O primitive, the equivalent of `std::cout`.
  static const Set<String> _builtins = {'print'};

  static const Set<String> _types = {
    'bool', 'char', 'char8_t', 'char16_t', 'char32_t', 'double', 'float',
    'int', 'long', 'short', 'signed', 'unsigned', 'void', 'wchar_t', 'size_t',
    'string', 'vector', 'map', 'set', 'unordered_map', 'unordered_set',
    'pair', 'queue', 'stack', 'deque', 'list', 'array', 'tuple', 'optional',
    'auto', 'class',
  };

  // Order matters: earlier patterns win when spans overlap.
  static final RegExp _tokenPattern = RegExp(
    r'(//[^\n]*)' // 1: line comment
    r'|(/\*[\s\S]*?\*/)' // 2: block comment
    r'|(#\s*\w+)' // 3: preprocessor
    r'|("(?:[^"\\]|\\.)*")' // 4: string literal
    r"|('(?:[^'\\]|\\.)*')" // 5: char literal
    r'|(\b\d+\.?\d*[fFlLuU]*\b)' // 6: number
    r'|(\b[A-Za-z_]\w*\b)' // 7: identifier
    r'|([{}()\[\];,.])' // 8: punctuation
    r'|([+\-*/%=<>!&|^~?:]+)', // 9: operator
  );

  static TextSpan build(String source, {required double fontSize, required bool enabled}) {
    final baseStyle = TextStyle(
      fontFamily: AppTheme.editorFontFamily,
      fontSize: fontSize,
      color: IdeColors.darkTextPrimary,
      height: 1.5,
    );

    if (!enabled || source.isEmpty) {
      return TextSpan(text: source, style: baseStyle);
    }

    final spans = <TextSpan>[];
    var lastEnd = 0;

    for (final match in _tokenPattern.allMatches(source)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: source.substring(lastEnd, match.start), style: baseStyle));
      }

      final text = match.group(0)!;
      spans.add(TextSpan(text: text, style: baseStyle.copyWith(color: _colorFor(match))));
      lastEnd = match.end;
    }

    if (lastEnd < source.length) {
      spans.add(TextSpan(text: source.substring(lastEnd), style: baseStyle));
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  static Color _colorFor(RegExpMatch match) {
    if (match.group(1) != null || match.group(2) != null) return IdeColors.syntaxComment;
    if (match.group(3) != null) return IdeColors.syntaxPreprocessor;
    if (match.group(4) != null || match.group(5) != null) return IdeColors.syntaxString;
    if (match.group(6) != null) return IdeColors.syntaxNumber;

    final identifier = match.group(7);
    if (identifier != null) {
      if (_keywords.contains(identifier)) return IdeColors.syntaxKeyword;
      if (_types.contains(identifier)) return IdeColors.syntaxType;
      if (_builtins.contains(identifier)) return IdeColors.syntaxFunction;
      // Heuristic: PascalCase identifiers read as classes; identifiers
      // immediately followed by '(' read as function calls/declarations.
      if (RegExp(r'^[A-Z]').hasMatch(identifier)) return IdeColors.syntaxClass;
      return IdeColors.syntaxDefault;
    }

    if (match.group(8) != null) return IdeColors.syntaxOperator;
    if (match.group(9) != null) return IdeColors.syntaxOperator;

    return IdeColors.syntaxDefault;
  }

  /// Separately detects `identifier(` occurrences so function calls can be
  /// colored — applied as a post-pass because it needs lookahead the main
  /// token regex doesn't have.
  static final RegExp functionCallPattern = RegExp(r'\b([A-Za-z_]\w*)\s*(?=\()');
}
