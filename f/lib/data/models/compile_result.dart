/// Result of a compilation-only step.
class CompileResult {
  final bool success;
  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;

  const CompileResult({
    required this.success,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
  });

  factory CompileResult.fromJson(Map<String, dynamic> json) {
    return CompileResult(
      success: json['success'] as bool? ?? false,
      stdout: json['stdout'] as String? ?? '',
      stderr: json['stderr'] as String? ?? '',
      exitCode: json['exit_code'] as int? ?? -1,
      duration: Duration(milliseconds: json['compile_time_ms'] as int? ?? 0),
    );
  }

  factory CompileResult.networkError(String message) => CompileResult(
        success: false,
        stdout: '',
        stderr: message,
        exitCode: -1,
        duration: Duration.zero,
      );
}
