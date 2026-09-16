import 'dart:math';

import '../models/compile_result.dart';
import '../models/run_result.dart';
import 'compiler_service.dart';

/// A fake compiler used so the UI can be fully built and tested before a
/// real backend exists.
///
/// It performs a handful of very shallow, purely textual sanity checks
/// (balanced braces/parens, presence of `int main`) and fabricates
/// plausible stdout by looking for simple `cout <<` statements. It never
/// pretends to be a real C++ compiler — it exists solely to exercise the
/// UI's success/failure/loading states.
class MockCompilerService implements CompilerService {
  final Random _random = Random();

  @override
  Future<CompileResult> compile(String sourceCode, {String standard = 'c++17'}) async {
    final started = DateTime.now();
    await _simulateLatency();

    final error = _findObviousError(sourceCode);
    final duration = DateTime.now().difference(started);

    if (error != null) {
      return CompileResult(
        success: false,
        stdout: '',
        stderr: error,
        exitCode: 1,
        duration: duration,
      );
    }

    return CompileResult(
      success: true,
      stdout: '',
      stderr: '',
      exitCode: 0,
      duration: duration,
    );
  }

  @override
  Future<RunResult> run(String sourceCode, String input, {String standard = 'c++17'}) async {
    final started = DateTime.now();
    final compileResult = await compile(sourceCode, standard: standard);

    if (!compileResult.success) {
      return RunResult.fromCompileFailure(compileResult.stderr);
    }

    await _simulateLatency(min: 40, max: 260);
    final duration = DateTime.now().difference(started);

    final stdout = _fakeStdout(sourceCode, input);

    return RunResult(
      success: true,
      stdout: stdout,
      stderr: '',
      exitCode: 0,
      duration: duration,
    );
  }

  Future<void> _simulateLatency({int min = 150, int max = 650}) {
    final ms = min + _random.nextInt(max - min);
    return Future.delayed(Duration(milliseconds: ms));
  }

  /// Extremely shallow static checks — enough to make the mock feel
  /// responsive to obvious mistakes without claiming to be a real parser.
  String? _findObviousError(String source) {
    final openBraces = '{'.allMatches(source).length;
    final closeBraces = '}'.allMatches(source).length;
    if (openBraces != closeBraces) {
      final line = _lineOf(source, source.length);
      return 'main.cpp:$line:1: error: expected \'}\' at end of input '
          '(mismatched braces: $openBraces open, $closeBraces close)';
    }

    final openParens = '('.allMatches(source).length;
    final closeParens = ')'.allMatches(source).length;
    if (openParens != closeParens) {
      return "main.cpp: error: expected ')' before end of input "
          '(mismatched parentheses)';
    }

    if (!RegExp(r'int\s+main\s*\(').hasMatch(source)) {
      return 'main.cpp: error: no matching function for call to \'main\'\n'
          "note: a program must define exactly one 'int main()' function";
    }

    // Detect a missing semicolon on the most common statement shapes.
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final trimmed = lines[i].trim();
      final endsOk = trimmed.isEmpty ||
          trimmed.endsWith(';') ||
          trimmed.endsWith('{') ||
          trimmed.endsWith('}') ||
          trimmed.endsWith(':') ||
          trimmed.endsWith(')') ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('//') ||
          trimmed.startsWith('/*');
      final looksLikeStatement =
          (trimmed.contains('cout') || trimmed.contains('cin') || trimmed.startsWith('return')) &&
              !trimmed.contains('//');
      if (looksLikeStatement && !endsOk) {
        return "main.cpp:${i + 1}:${trimmed.length + 1}: error: expected ';' before end of line";
      }
    }

    return null;
  }

  int _lineOf(String source, int index) {
    return '\n'.allMatches(source.substring(0, min(index, source.length))).length + 1;
  }

  /// Produces plausible-looking output for `cout << "literal"` statements
  /// and a friendly hint for anything it can't fake.
  String _fakeStdout(String source, String input) {
    final buffer = StringBuffer();
    final coutLiteral = RegExp(r'cout\s*<<\s*"([^"]*)"');
    final matches = coutLiteral.allMatches(source);

    if (matches.isEmpty) {
      buffer.writeln('[Mock run — no literal cout output detected]');
      if (input.isNotEmpty) {
        buffer.writeln('Received stdin:');
        buffer.writeln(input);
      }
    } else {
      for (final m in matches) {
        buffer.write(m.group(1));
        if (source.substring(m.end).trimLeft().startsWith('<< endl') ||
            source.substring(m.end, min(m.end + 12, source.length)).contains(r'\n')) {
          buffer.writeln();
        }
      }
    }

    return buffer.toString();
  }
}
