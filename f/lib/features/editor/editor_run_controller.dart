import 'package:flutter/foundation.dart';

import '../../data/models/compile_result.dart';
import '../../data/models/run_result.dart';
import '../../data/services/compiler_service.dart';
import '../../widgets/output_console/output_console.dart';

/// Drives the compile/run workflow for the editor screen and exposes the
/// console state. Contains no UI code — it is the single place that talks
/// to [CompilerService], keeping widgets free of compiler logic per the
/// architecture requirement.
class EditorRunController extends ChangeNotifier {
  CompilerService compilerService;

  EditorRunController({required this.compilerService});

  /// Swaps the backend the controller talks to. Called whenever the
  /// endpoint in Settings changes, so a new compiler URL takes effect
  /// immediately instead of only after a full app restart.
  void updateCompilerService(CompilerService newService) {
    if (identical(newService, compilerService)) return;
    compilerService = newService;
  }

  ConsoleStatus status = ConsoleStatus.idle;
  CompileResult? lastCompileResult;
  RunResult? lastRunResult;

  bool _busy = false;
  bool get isBusy => _busy;

  Future<void> compileOnly(String source, {required String standard}) async {
    if (_busy) return;
    _busy = true;
    status = ConsoleStatus.compiling;
    lastRunResult = null;
    notifyListeners();

    try {
      final result = await compilerService.compile(source, standard: standard);
      lastCompileResult = result;
      status = result.success ? ConsoleStatus.success : ConsoleStatus.failure;
    } catch (e) {
      status = ConsoleStatus.error;
      lastCompileResult = CompileResult.networkError(
        'Unable to connect to compiler server.\n\nCheck your internet connection or compiler server URL.',
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> compileAndRun(String source, String stdin, {required String standard}) async {
    if (_busy) return;
    _busy = true;
    status = ConsoleStatus.running;
    lastCompileResult = null;
    notifyListeners();

    try {
      final result = await compilerService.run(source, stdin, standard: standard);
      lastRunResult = result;
      status = result.compileFailed
          ? ConsoleStatus.failure
          : (result.success ? ConsoleStatus.success : ConsoleStatus.failure);
    } catch (e) {
      status = ConsoleStatus.error;
      lastRunResult = RunResult.networkError(
        'Unable to connect to compiler server.\n\nCheck your internet connection or compiler server URL.',
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clear() {
    status = ConsoleStatus.idle;
    lastCompileResult = null;
    lastRunResult = null;
    notifyListeners();
  }

  /// Extracts the first "line: N" reference from whichever error text is
  /// currently displayed, if any — used to jump the editor cursor there.
  int? firstErrorLine() {
    final text = lastRunResult?.stderr ?? lastCompileResult?.stderr;
    if (text == null) return null;
    final match = RegExp(r':(\d+):').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}
