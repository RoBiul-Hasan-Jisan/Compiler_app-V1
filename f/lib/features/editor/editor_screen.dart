import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/cpp_file.dart';
import '../../data/repositories/file_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/services/api_compiler_service.dart';
import '../../data/services/compiler_service.dart';
import '../../data/services/mock_compiler_service.dart';
import '../../widgets/code_editor/cpp_code_editor.dart';
import '../../widgets/code_editor/cpp_editor_controller.dart';
import '../../widgets/code_editor/editor_accessory_bar.dart';
import '../../widgets/code_editor/editor_dialogs.dart';
import '../../widgets/code_editor/editor_toolbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/output_console/input_panel.dart';
import '../../widgets/output_console/output_console.dart';
import '../settings/settings_screen.dart';
import 'editor_run_controller.dart';

/// The primary IDE surface: editor, input, output, and the compile/run
/// workflow, all wired together.
///
/// [initialFileId] selects which file to open; when null it falls back to
/// the last file the user had open, or the first available file.
class EditorScreen extends StatefulWidget {
  final String? initialFileId;

  const EditorScreen({super.key, this.initialFileId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final CppEditorController _codeController;
  final TextEditingController _stdinController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final GlobalKey<CppCodeEditorState> _editorKey = GlobalKey<CppCodeEditorState>();

  String? _openFileId;
  CppFile? _openFile;
  Timer? _autosaveDebounce;

  // Kept as an instance so ApiCompilerService's http.Client can be reused
  // and disposed correctly across rebuilds.
  CompilerService? _compilerService;
  EditorRunController? _runController;

  @override
  void initState() {
    super.initState();
    _codeController = CppEditorController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeFile());
  }

  Future<void> _initializeFile() async {
    final fileRepo = context.read<FileRepository>();
    if (fileRepo.isLoading) {
      // Wait for the repository's initial load before selecting a file.
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 30));
        return context.read<FileRepository>().isLoading;
      });
    }

    final repo = context.read<FileRepository>();
    final targetId = widget.initialFileId ?? repo.lastOpenFileId ?? (repo.files.isNotEmpty ? repo.files.first.id : null);

    if (targetId == null) return;
    _openFileFromRepo(targetId);
  }

  void _openFileFromRepo(String id) {
    final repo = context.read<FileRepository>();
    final file = repo.byId(id);
    if (file == null) return;

    setState(() {
      _openFileId = id;
      _openFile = file;
      _codeController.text = file.content;
    });
    repo.markOpened(id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsRepository>().settings;
    _codeController
      ..fontSize = settings.fontSize
      ..tabSize = settings.tabSize
      ..syntaxHighlightingEnabled = settings.syntaxHighlighting;

    _ensureCompilerService(settings);
  }

  void _ensureCompilerService(IdeSettings settings) {
    // Set to true only if you don't have the compiler backend (see the
    // bundled cpp_compiler_backend/) running — the UI needs no other
    // changes either way.
    const useMockCompiler = false;

    if (useMockCompiler) {
      _compilerService ??= MockCompilerService();
    } else {
      final existing = _compilerService;
      if (existing is! ApiCompilerService || existing.baseUrl != settings.compilerApiUrl) {
        if (existing is ApiCompilerService) existing.dispose();
        _compilerService = ApiCompilerService(
          baseUrl: settings.compilerApiUrl,
          timeout: Duration(seconds: settings.compilerTimeoutSeconds),
        );
      }
    }

    if (_runController == null) {
      _runController = EditorRunController(compilerService: _compilerService!);
    } else {
      _runController!.updateCompilerService(_compilerService!);
    }
  }

  void _onSourceChanged(String text) {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 500), () {
      final id = _openFileId;
      if (id != null) {
        context.read<FileRepository>().updateContent(id, text);
      }
    });
    setState(() {}); // Refresh gutter/line count immediately.
  }

  Future<void> _saveNow() async {
    final id = _openFileId;
    if (id == null) return;
    _autosaveDebounce?.cancel();
    await context.read<FileRepository>().updateContent(id, _codeController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved'), duration: Duration(milliseconds: 800)),
      );
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _codeController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _compile() async {
    final settings = context.read<SettingsRepository>().settings;
    await _runController!.compileOnly(_codeController.text, standard: settings.cppStandard);
  }

  Future<void> _run() async {
    final settings = context.read<SettingsRepository>().settings;
    await _runController!.compileAndRun(_codeController.text, _stdinController.text, standard: settings.cppStandard);
  }

  Future<void> _goToLine() async {
    final lineCount = '\n'.allMatches(_codeController.text).length + 1;
    final line = await showGoToLineDialog(context, lineCount);
    if (line != null) {
      _editorKey.currentState?.goToLine(line);
    }
  }

  void _jumpToErrorLine(int line) {
    _editorKey.currentState?.goToLine(line);
  }

  void _format() {
    // A full formatter (clang-format) belongs on the backend; the local
    // action normalizes trailing whitespace as a lightweight placeholder.
    final cleaned = _codeController.text.split('\n').map((l) => l.trimRight()).join('\n');
    _codeController.text = cleaned;
    _onSourceChanged(cleaned);
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    _codeController.dispose();
    _stdinController.dispose();
    _editorFocusNode.dispose();
    if (_compilerService is ApiCompilerService) {
      (_compilerService as ApiCompilerService).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>().settings;

    if (_openFile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor')),
        body: const EmptyState(
          icon: Icons.code,
          title: 'No file open',
          message: 'Open or create a C++ file from Home or Files to start coding.',
        ),
      );
    }

    return ChangeNotifierProvider<EditorRunController>.value(
      value: _runController!,
      child: Consumer<EditorRunController>(
        builder: (context, run, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_openFile!.name, style: const TextStyle(fontFamily: AppTheme.editorFontFamily)),
              actions: [
                IconButton(icon: const Icon(Icons.save_outlined), tooltip: 'Save', onPressed: _saveNow),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'copy':
                        _copyCode();
                        break;
                      case 'wrap':
                        context.read<SettingsRepository>().update((s) => s.copyWith(wordWrap: !s.wordWrap));
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'copy', child: Text('Copy code')),
                    PopupMenuItem(value: 'wrap', child: Text(settings.wordWrap ? 'Disable word wrap' : 'Enable word wrap')),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  EditorToolbar(
                    onUndo: () {}, // TextField's built-in undo covers most cases on-device.
                    onRedo: () {},
                    onSearch: () => showSearchReplaceSheet(context, _codeController),
                    onGoToLine: _goToLine,
                    onFormat: _format,
                    onSettings: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  Expanded(
                    child: CppCodeEditor(
                      key: _editorKey,
                      controller: _codeController,
                      focusNode: _editorFocusNode,
                      showLineNumbers: settings.showLineNumbers,
                      wordWrap: settings.wordWrap,
                      onChanged: _onSourceChanged,
                    ),
                  ),
                  EditorAccessoryBar(controller: _codeController, focusNode: _editorFocusNode),
                  InputPanel(controller: _stdinController, onRunWithInput: _run),
                  OutputConsole(
                    status: run.status,
                    compileResult: run.lastCompileResult,
                    runResult: run.lastRunResult,
                    onClear: run.clear,
                    onErrorTap: _jumpToErrorLine,
                  ),
                  _buildActionBar(run),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar(EditorRunController run) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: IdeColors.darkSurface,
        border: Border(top: BorderSide(color: IdeColors.darkBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: run.isBusy ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: run.isBusy ? null : _compile,
              icon: const Icon(Icons.build_outlined),
              label: const Text('Compile'),
            ),
          ),
        ],
      ),
    );
  }
}
