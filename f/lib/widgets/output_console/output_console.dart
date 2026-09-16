import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/compile_result.dart';
import '../../data/models/run_result.dart';

enum ConsoleStatus { idle, compiling, running, success, failure, error }

/// Professional terminal-style console showing compile/run output.
///
/// Consumes plain data (status + results) rather than talking to
/// [CompilerService] itself, keeping it a dumb, reusable presentation
/// widget.
class OutputConsole extends StatefulWidget {
  final ConsoleStatus status;
  final CompileResult? compileResult;
  final RunResult? runResult;
  final VoidCallback onClear;
  final void Function(int line)? onErrorTap;

  const OutputConsole({
    super.key,
    required this.status,
    this.compileResult,
    this.runResult,
    required this.onClear,
    this.onErrorTap,
  });

  @override
  State<OutputConsole> createState() => _OutputConsoleState();
}

class _OutputConsoleState extends State<OutputConsole> {
  bool _expanded = false;

  String get _combinedOutputForCopy {
    final buffer = StringBuffer();
    if (widget.compileResult != null) {
      buffer.writeln(widget.compileResult!.stdout);
      buffer.writeln(widget.compileResult!.stderr);
    }
    if (widget.runResult != null) {
      buffer.writeln(widget.runResult!.stdout);
      buffer.writeln(widget.runResult!.stderr);
    }
    return buffer.toString().trim();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _combinedOutputForCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Output copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: _expanded ? 420 : 220,
      decoration: const BoxDecoration(
        color: IdeColors.darkSurface,
        border: Border(top: BorderSide(color: IdeColors.darkBorder)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: IdeColors.darkBorder),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'OUTPUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: IdeColors.darkTextSecondary,
            ),
          ),
          const SizedBox(width: 10),
          _StatusChip(status: widget.status),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: IdeColors.darkTextSecondary),
            tooltip: 'Copy output',
            splashRadius: 18,
            onPressed: _copy,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: IdeColors.darkTextSecondary),
            tooltip: 'Clear console',
            splashRadius: 18,
            onPressed: widget.onClear,
          ),
          IconButton(
            icon: Icon(
              _expanded ? Icons.close_fullscreen : Icons.open_in_full,
              size: 18,
              color: IdeColors.darkTextSecondary,
            ),
            tooltip: _expanded ? 'Collapse console' : 'Expand console',
            splashRadius: 18,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (widget.status) {
      case ConsoleStatus.idle:
        return const _EmptyConsole();
      case ConsoleStatus.compiling:
        return const _BusyMessage(label: 'Compiling…');
      case ConsoleStatus.running:
        return const _BusyMessage(label: 'Running…');
      case ConsoleStatus.error:
        return _ErrorMessage(message: widget.runResult?.stderr ?? widget.compileResult?.stderr ?? 'Unknown error');
      case ConsoleStatus.success:
      case ConsoleStatus.failure:
        return _buildResult();
    }
  }

  Widget _buildResult() {
    final compile = widget.compileResult;
    final run = widget.runResult;
    final children = <Widget>[];

    if (compile != null) {
      if (compile.success) {
        children.add(_SuccessLine('Compilation successful — build completed in ${_fmt(compile.duration)}'));
      } else {
        children.add(const _SectionLabel('COMPILATION ERROR'));
        children.add(_ErrorText(compile.stderr, onErrorTap: widget.onErrorTap));
      }
    }

    if (run != null) {
      if (run.compileFailed) {
        children.add(const _SectionLabel('COMPILATION ERROR'));
        children.add(_ErrorText(run.stderr, onErrorTap: widget.onErrorTap));
      } else {
        if (run.stdout.isNotEmpty) {
          children.add(const _SectionLabel('PROGRAM OUTPUT'));
          children.add(_PlainText(run.stdout));
        }
        if (run.stderr.isNotEmpty) {
          children.add(const _SectionLabel('STDERR'));
          children.add(_ErrorText(run.stderr, onErrorTap: widget.onErrorTap));
        }
        children.add(const SizedBox(height: 8));
        children.add(_MetaLine('Process finished with exit code ${run.exitCode}'));
        children.add(_MetaLine('Execution time: ${_fmt(run.duration)}'));
      }
    }

    if (children.isEmpty) {
      return const _EmptyConsole();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  String _fmt(Duration d) => '${(d.inMilliseconds / 1000).toStringAsFixed(2)}s';
}

class _StatusChip extends StatelessWidget {
  final ConsoleStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String label;
    switch (status) {
      case ConsoleStatus.idle:
        color = IdeColors.darkTextSecondary;
        label = 'Idle';
        break;
      case ConsoleStatus.compiling:
        color = IdeColors.warning;
        label = 'Compiling';
        break;
      case ConsoleStatus.running:
        color = IdeColors.accent;
        label = 'Running';
        break;
      case ConsoleStatus.success:
        color = IdeColors.success;
        label = 'Success';
        break;
      case ConsoleStatus.failure:
        color = IdeColors.danger;
        label = 'Failed';
        break;
      case ConsoleStatus.error:
        color = IdeColors.danger;
        label = 'Error';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyConsole extends StatelessWidget {
  const _EmptyConsole();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Run or compile your program to see output here.',
        style: TextStyle(color: IdeColors.darkTextSecondary, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _BusyMessage extends StatelessWidget {
  final String label;
  const _BusyMessage({required this.label});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: IdeColors.accent),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: IdeColors.darkTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, color: IdeColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: IdeColors.danger, fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: IdeColors.darkTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _PlainText extends StatelessWidget {
  final String text;
  const _PlainText(this.text);
  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.editorFontFamily,
        fontSize: 13,
        color: IdeColors.darkTextPrimary,
        height: 1.4,
      ),
    );
  }
}

class _SuccessLine extends StatelessWidget {
  final String text;
  const _SuccessLine(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: IdeColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: IdeColors.success, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String text;
  const _MetaLine(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: AppTheme.editorFontFamily,
        fontSize: 12,
        color: IdeColors.darkTextSecondary,
      ),
    );
  }
}

/// Renders compiler error text and, when a "file:line:col:" pattern is
/// detected, makes each error line tappable so the editor cursor can jump
/// there.
class _ErrorText extends StatelessWidget {
  final String text;
  final void Function(int line)? onErrorTap;
  const _ErrorText(this.text, {this.onErrorTap});

  static final RegExp _lineRef = RegExp(r'^\S+:(\d+):');

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final match = _lineRef.firstMatch(line);
        final lineNumber = match != null ? int.tryParse(match.group(1)!) : null;

        final textWidget = Text(
          line,
          style: const TextStyle(
            fontFamily: AppTheme.editorFontFamily,
            fontSize: 13,
            color: IdeColors.danger,
            height: 1.4,
          ),
        );

        if (lineNumber != null && onErrorTap != null) {
          return InkWell(
            onTap: () => onErrorTap!(lineNumber),
            child: textWidget,
          );
        }
        return textWidget;
      }).toList(),
    );
  }
}
