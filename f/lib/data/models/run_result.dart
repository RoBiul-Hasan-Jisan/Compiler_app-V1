/// Result of compiling *and* running a program.
class RunResult {
  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;

  /// Populated when compilation failed before execution could start.
  final bool compileFailed;

  const RunResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
    this.compileFailed = false,
  });

  factory RunResult.fromJson(Map<String, dynamic> json) {
    return RunResult(
      success: json['success'] as bool? ?? false,
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
      exitCode: json['exit_code'] as int? ?? -1,
      duration: Duration(milliseconds: json['execution_time_ms'] as int? ?? 0),
    );
  }

  factory RunResult.fromCompileFailure(String stderr) => RunResult(
        success: false,
        stdout: '',
        stderr: stderr,
        exitCode: -1,
        duration: Duration.zero,
        compileFailed: true,
      );

  factory RunResult.networkError(String message) => RunResult(
        success: false,
        stdout: '',
        stderr: message,
        exitCode: -1,
        duration: Duration.zero,
      );
}
