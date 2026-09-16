import '../models/compile_result.dart';
import '../models/run_result.dart';

/// Contract for anything capable of compiling and/or running C++ source.
///
/// The UI layer only ever depends on this interface, never on a concrete
/// implementation, so the backend (mock, HTTP API, or a future embedded/
/// local compiler) can be swapped without touching any widget.
abstract class CompilerService {
  /// Compiles [sourceCode] only. Does not execute the resulting binary.
  Future<CompileResult> compile(String sourceCode, {String standard});

  /// Compiles [sourceCode] and, if compilation succeeds, runs it with
  /// [input] fed to stdin.
  Future<RunResult> run(String sourceCode, String input, {String standard});
}
