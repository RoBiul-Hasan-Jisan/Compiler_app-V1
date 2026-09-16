import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import 'cpp_editor_controller.dart';

/// A self-contained C++ editor surface: line-number gutter, current-line
/// highlight, syntax-highlighted text, auto-indent, and auto-closing
/// brackets. Wrap it with [CppEditorToolbar] and [EditorAccessoryBar] for
/// the full editing experience.
class CppCodeEditor extends StatefulWidget {
  final CppEditorController controller;
  final FocusNode focusNode;
  final bool showLineNumbers;
  final bool wordWrap;
  final ValueChanged<String>? onChanged;

  const CppCodeEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    this.showLineNumbers = true,
    this.wordWrap = false,
    this.onChanged,
  });

  @override
  State<CppCodeEditor> createState() => CppCodeEditorState();
}

class CppCodeEditorState extends State<CppCodeEditor> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _gutterController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  static const double _lineHeightMultiplier = 1.5;

  @override
  void initState() {
    super.initState();
    _verticalController.addListener(_syncGutter);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _verticalController.removeListener(_syncGutter);
    widget.controller.removeListener(_onTextChanged);
    _verticalController.dispose();
    _gutterController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  void _syncGutter() {
    if (_gutterController.hasClients) {
      _gutterController.jumpTo(_verticalController.offset);
    }
  }

  void _onTextChanged() {
    setState(() {}); // Refresh line count / current-line highlight.
  }

  double get _lineHeight => widget.controller.fontSize * _lineHeightMultiplier;

  int get _currentLine {
    final offset = widget.controller.selection.baseOffset;
    if (offset < 0) return 0;
    final upToCursor = widget.controller.text.substring(0, offset.clamp(0, widget.controller.text.length));
    return '\n'.allMatches(upToCursor).length;
  }

  int get _lineCount => '\n'.allMatches(widget.controller.text).length + 1;

  /// Handles Enter for auto-indent and bracket auto-close/skip-over. Wired
  /// through a [KeyboardListener] because [TextField] alone doesn't expose
  /// enough control over insertion behavior for these features.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      widget.controller.insertNewlineWithAutoIndent();
      widget.onChanged?.call(widget.controller.text);
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (character != null && character.isNotEmpty) {
      if (widget.controller.handleSkipOverClosing(character)) {
        return KeyEventResult.handled;
      }
      if (widget.controller.handleAutoClose(character)) {
        widget.onChanged?.call(widget.controller.text);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final gutterWidth = widget.showLineNumbers ? (_lineCount.toString().length * 10.0 + 24) : 0.0;

    final editorField = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      maxLines: null,
      minLines: null,
      expands: true,
      scrollController: _verticalController,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      cursorColor: IdeColors.accent,
      style: TextStyle(
        fontFamily: AppTheme.editorFontFamily,
        fontSize: widget.controller.fontSize,
        height: _lineHeightMultiplier,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: widget.onChanged,
    );

    final wrappedField = widget.wordWrap
        ? editorField
        : SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 2000, // Generous canvas so long lines scroll horizontally.
              child: editorField,
            ),
          );

    return Container(
      color: IdeColors.darkBackground,
      child: Focus(
        onKeyEvent: _handleKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showLineNumbers)
              _LineNumberGutter(
                width: gutterWidth,
                lineCount: _lineCount,
                currentLine: _currentLine,
                lineHeight: _lineHeight,
                fontSize: widget.controller.fontSize,
                scrollController: _gutterController,
              ),
            Expanded(
              child: Stack(
                children: [
                  _CurrentLineHighlight(
                    currentLine: _currentLine,
                    lineHeight: _lineHeight,
                    scrollController: _verticalController,
                  ),
                  wrappedField,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Moves the cursor to [line] (1-indexed) and requests focus — used by
  /// "Go to line" and by tapping a compiler error.
  void goToLine(int line) {
    final lines = widget.controller.text.split('\n');
    final target = line.clamp(1, lines.length) - 1;
    var offset = 0;
    for (var i = 0; i < target; i++) {
      offset += lines[i].length + 1;
    }
    widget.controller.selection = TextSelection.collapsed(offset: offset);
    widget.focusNode.requestFocus();
  }
}

class _LineNumberGutter extends StatelessWidget {
  final double width;
  final int lineCount;
  final int currentLine;
  final double lineHeight;
  final double fontSize;
  final ScrollController scrollController;

  const _LineNumberGutter({
    required this.width,
    required this.lineCount,
    required this.currentLine,
    required this.lineHeight,
    required this.fontSize,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: IdeColors.darkSurface,
        border: Border(right: BorderSide(color: IdeColors.darkBorder)),
      ),
      child: IgnorePointer(
        child: SingleChildScrollView(
          controller: scrollController,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(lineCount, (i) {
              final isCurrent = i == currentLine;
              return SizedBox(
                height: lineHeight,
                width: width - 12,
                child: Text(
                  '${i + 1}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppTheme.editorFontFamily,
                    fontSize: fontSize * 0.85,
                    color: isCurrent ? IdeColors.accent : IdeColors.darkTextSecondary,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CurrentLineHighlight extends StatelessWidget {
  final int currentLine;
  final double lineHeight;
  final ScrollController scrollController;

  const _CurrentLineHighlight({
    required this.currentLine,
    required this.lineHeight,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final scrollOffset = scrollController.hasClients ? scrollController.offset : 0.0;
        final top = 12 + currentLine * lineHeight - scrollOffset;
        return Positioned(
          left: 0,
          right: 0,
          top: top,
          height: lineHeight,
          child: IgnorePointer(
            child: Container(color: IdeColors.darkSurfaceAlt.withOpacity(0.5)),
          ),
        );
      },
    );
  }
}
