/// Starter templates offered when creating a new C++ file.
///
/// Written in mcpp syntax (see the mcpp-compiler README) rather than real
/// C++: no `#include`, no `cout`/`cin`, `print(...)` instead of
/// `std::cout <<`. These are raw strings (r'''...''') so that `\n` inside
/// the program text reaches the compiler as `\n` (a new line) instead of
/// being turned into a literal backslash-n.
class CppTemplates {
  CppTemplates._();

  static const String blank = r'''
int main() {
    return 0;
}
''';

  static const String helloWorld = r'''
// Every program starts at main().
// print(...) shows text; \n starts a new line.
int main() {
    print("Hello World\n");
    return 0;
}
''';

  static const String competitiveProgramming = r'''
int solve(int n) {
    int total = 0;
    for (int i = 0; i < n; i = i + 1) {
        total = total + i;
    }
    return total;
}

int main() {
    int n = 10;
    print("sum 0..", n, " = ", solve(n), "\n");
    return 0;
}
''';

  static const Map<String, String> all = {
    'Blank': blank,
    'Hello World': helloWorld,
    'Competitive Programming': competitiveProgramming,
  };
}
