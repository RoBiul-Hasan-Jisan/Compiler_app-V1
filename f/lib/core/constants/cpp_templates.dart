/// Starter templates offered when creating a new C++ file.
///
/// Written in mcpp syntax (see the mcpp-compiler README) rather than real
/// C++: no `#include`, no `cout`/`cin`, `print(...)` instead of
/// `std::cout <<`. If you swap the backend back to a real g++ server via
/// ApiCompilerService, update these back to standard C++ headers first —
/// mcpp and real C++ are not source-compatible.
class CppTemplates {
  CppTemplates._();

  static const String blank = '''
int main() {
    return 0;
}
''';

  static const String helloWorld = '''
int main() {
    print("Hello World\\n");
    return 0;
}
''';

  static const String competitiveProgramming = '''
int solve(int n) {
    int total = 0;
    for (int i = 0; i < n; i = i + 1) {
        total = total + i;
    }
    return total;
}

int main() {
    int n = 10;
    print("sum 0..", n, " = ", solve(n), "\\n");
    return 0;
}
''';

  static const Map<String, String> all = {
    'Blank': blank,
    'Hello World': helloWorld,
    'Competitive Programming': competitiveProgramming,
  };
}
