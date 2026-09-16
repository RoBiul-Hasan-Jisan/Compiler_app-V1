import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/compile_result.dart';
import '../models/run_result.dart';
import 'compiler_service.dart';

/// Talks to a real C++ compiler backend over HTTP.
///
/// Expected contract:
///   POST {baseUrl}/compile   -> compile only
///   POST {baseUrl}/run       -> compile + execute
///
/// Request body:
/// {
///   "language": "cpp",
///   "standard": "c++17",
///   "source": "...",
///   "stdin": "..."
/// }
///
/// Response body:
/// {
///   "success": true,
///   "stdout": "...",
///   "stderr": "...",
///   "exit_code": 0,
///   "compile_time_ms": 742,
///   "execution_time_ms": 43
/// }
class ApiCompilerService implements CompilerService {
  final String baseUrl;
  final Duration timeout;
  final http.Client _client;

  ApiCompilerService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _endpoint(String path) => Uri.parse('$baseUrl$path');

  Map<String, dynamic> _body(String source, String stdin, String standard) => {
        'language': 'cpp',
        'standard': standard,
        'source': source,
        'stdin': stdin,
      };

  @override
  Future<CompileResult> compile(String sourceCode, {String standard = 'c++17'}) async {
    try {
      final response = await _client
          .post(
            _endpoint('/compile'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(_body(sourceCode, '', standard)),
          )
          .timeout(timeout);

      if (response.statusCode >= 500) {
        return CompileResult.networkError(
          'Compiler server error (HTTP ${response.statusCode}). Please try again later.',
        );
      }
      if (response.statusCode >= 400) {
        return CompileResult.networkError(
          'Request rejected by compiler server (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return CompileResult.fromJson(decoded);
    } on TimeoutException {
      return CompileResult.networkError(
        'Compilation timed out after ${timeout.inSeconds}s.',
      );
    } on FormatException {
      return CompileResult.networkError('Received a malformed response from the compiler server.');
    } catch (e) {
      return CompileResult.networkError(
        'Unable to connect to compiler server.\n\nCheck your internet connection or compiler server URL.',
      );
    }
  }

  @override
  Future<RunResult> run(String sourceCode, String input, {String standard = 'c++17'}) async {
    try {
      final response = await _client
          .post(
            _endpoint('/run'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(_body(sourceCode, input, standard)),
          )
          .timeout(timeout);

      if (response.statusCode >= 500) {
        return RunResult.networkError(
          'Compiler server error (HTTP ${response.statusCode}). Please try again later.',
        );
      }
      if (response.statusCode >= 400) {
        // A 4xx on /run is most commonly a compilation failure surfaced
        // with structured info in the body — try to parse it as such.
        try {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          if (decoded['success'] == false && (decoded['stdout'] as String? ?? '').isEmpty) {
            return RunResult.fromCompileFailure(decoded['stderr'] as String? ?? 'Compilation failed.');
          }
        } catch (_) {
          // fall through to generic error below
        }
        return RunResult.networkError(
          'Request rejected by compiler server (HTTP ${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return RunResult.fromJson(decoded);
    } on TimeoutException {
      return RunResult.networkError(
        'Execution timed out after ${timeout.inSeconds}s.',
      );
    } on FormatException {
      return RunResult.networkError('Received a malformed response from the compiler server.');
    } catch (e) {
      return RunResult.networkError(
        'Unable to connect to compiler server.\n\nCheck your internet connection or compiler server URL.',
      );
    }
  }

  void dispose() => _client.close();
}
