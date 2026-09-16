# C++ IDE (Flutter)

A lightweight, professional C++ coding IDE for mobile — Home, Editor, File
Management, and the compile/run workflow, wired by default to a real
`g++`-backed compiler server (see `cpp_compiler_backend/` alongside this
project). A `MockCompilerService` is also included for UI-only development
without the backend running.

## Getting started

This repo contains only the `lib/` Dart source and `pubspec.yaml` — it does
not include the generated Android/iOS/web platform folders, since those are
large, mostly-boilerplate directories that Flutter generates for you.

```bash
# 1. Unzip this project, cd into it
cd cpp_ide

# 2. Generate the platform folders (android/, ios/, etc.)
flutter create .

# 3. Get packages
flutter pub get

# 4. Run (Android emulator or device)
flutter run
```

By default the app talks to `http://10.0.2.2:8000` (the Android emulator's
alias for your host machine's `localhost`) and expects the real compiler
backend (`cpp_compiler_backend/`) to be running there — see "Compiler
backend" below to start it. If you just want to click around the UI
without setting up the backend, flip `useMockCompiler` back to `true` in
`lib/features/editor/editor_screen.dart`.

## Compiler backend

The UI never contains compiler logic. Everything goes through the
`CompilerService` abstraction in `lib/data/services/compiler_service.dart`:

```dart
abstract class CompilerService {
  Future<CompileResult> compile(String sourceCode, {String standard});
  Future<RunResult> run(String sourceCode, String input, {String standard});
}
```

Two backend servers implement this contract, and either can be dropped in
without touching a single line of Flutter code — that's the entire point
of the abstraction:

- **`mcpp-compiler/server/`** — a from-scratch C++-*flavoured* language
  (own lexer/parser/interpreter, no external toolchain, portable
  sandboxing that works identically on Windows/Linux/Mac). This is what
  the app is currently pointed at by default. Start it:

  ```bash
  cd mcpp-compiler/server
  pip install -r requirements.txt
  python3 app.py
  ```

  See `mcpp-compiler/README.md` for the full language reference — it's
  C++-flavoured syntax, not real C++ (no STL, no `#include`, no
  `cin`/`cout` — use `print(...)` instead). The default "New File"
  templates in this app are already written in mcpp syntax.

- **`cpp_compiler_backend/`** — a real g++-backed server for actual C++
  (see its own README for setup and Windows caveats). Point
  `Settings → Compiler → Compiler endpoint` at it instead if you want to
  compile real C++ — no app code changes needed either way.

Regardless of which server you run, both listen on the same default port
(`8000`), so the Android emulator default (`http://10.0.2.2:8000`) works
for either — just start the one you want and leave the app's config
alone. To point at a different host/port, use `Settings → Compiler →
Compiler endpoint`, or `--dart-define=COMPILER_API_URL=https://your-server.com`
at build time.

- **`MockCompilerService`** — a fallback for UI-only development when you
  don't want any backend running. Does shallow textual checks (balanced
  braces/parens, presence of `int main`, obviously missing semicolons) and
  fabricates output from literal `cout << "..."` statements. It never
  claims to be a real compiler — flip `useMockCompiler` to `true` in
  `lib/features/editor/editor_screen.dart` to use it instead.

You can also point `Settings → Compiler → Compiler endpoint` at any other
server implementing the same contract.


### Backend security

`cpp_compiler_backend/app.py` treats submitted code as **untrusted** and
applies process-level limits (CPU time, memory, process count, file size,
execution timeout, automatic temp-directory cleanup). It does **not**
disable network access or sandbox the filesystem — see the security notes
at the bottom of that file and in its README before exposing it publicly.

## Architecture

```
lib/
├── core/            # config, constants (C++ templates), theme
├── data/
│   ├── models/      # CompileResult, RunResult, CppFile
│   ├── services/    # CompilerService + Mock/Api implementations,
│   │                # local file storage
│   └── repositories/# FileRepository, SettingsRepository (ChangeNotifier)
├── features/
│   ├── home/        # Home screen (recent files, search, new file)
│   ├── editor/       # Editor screen + compile/run controller
│   ├── files/        # File explorer + new/rename dialogs
│   └── settings/     # Editor/compiler/appearance settings
└── widgets/
    ├── code_editor/  # CppCodeEditor, syntax highlighter, toolbar,
    │                 # accessory bar, search/replace & go-to-line dialogs
    ├── output_console/ # Terminal-style console + stdin input panel
    ├── file_card/    # Reusable file list item
    └── common/       # Root shell (bottom nav), empty states
```

State management uses `provider` with two long-lived `ChangeNotifier`s
(`FileRepository`, `SettingsRepository`) injected at the app root; the
editor's compile/run state lives in a scoped `EditorRunController`.
Persistence is via `shared_preferences` (source files, recent files, and
all settings survive an app restart).

## What's implemented (Phases 1–2 of the brief)

- Dark Material 3 IDE theme (light/system also available)
- Home screen: greeting, recent files, search, new-file flow
- File management: create, rename, delete, duplicate, `.cpp`-only
- Local persistence, reopens last file on restart
- Editor: line numbers, current-line highlight, C++ syntax highlighting
  (keywords/types/strings/numbers/comments/preprocessor/operators/classes),
  auto-indent, auto-closing brackets, search & replace, go-to-line,
  horizontal/vertical scrolling, word-wrap toggle
- Editor toolbar + keyboard accessory bar (`{} () [] ; = <> # Tab`)
- Compile/Run workflow against `CompilerService`, with loading, success,
  failure, and network-error states; tappable errors jump the cursor
- stdin input panel (clear/paste/run-with-input)
- Terminal-style output console (stdout/stderr/compiler errors, exit code,
  execution time, copy/clear/expand/collapse)
- Settings: font size, tab size, word wrap, line numbers, auto-indent,
  syntax highlighting, C++ standard (17/20/23), compiler endpoint,
  compilation timeout, theme

## What's intentionally stubbed for later phases

- Real compiler backend (Phase 3) — `ApiCompilerService` is ready; you
  need a server behind it.
- A real `clang-format` integration for the "Format" action (currently a
  lightweight trailing-whitespace cleanup placeholder).
- Full undo/redo toolbar wiring beyond the platform text field's built-in
  undo (Flutter doesn't expose a public undo/redo API on plain
  `TextEditingController` without additional package support).
