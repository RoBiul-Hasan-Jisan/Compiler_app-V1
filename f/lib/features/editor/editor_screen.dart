import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_state.dart';
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

class _EditorScreenState extends State<EditorScreen> with WidgetsBindingObserver {
  late final CppEditorController _codeController;
  final TextEditingController _stdinController = TextEditingController();
  final FocusNode _editorFocusNode = FocusNode();
  final GlobalKey<CppCodeEditorState> _editorKey = GlobalKey<CppCodeEditorState>();

  String? _openFileId;
  CppFile? _openFile;
  Timer? _autosaveDebounce;

  /// Full-screen mode: hides the app bar, bottom navigation, input and
  /// output panels so the code editor gets the whole screen.
  bool _fullscreen = false;

  // Kept as an instance so ApiCompilerService's http.Client can be reused
  // and disposed correctly across rebuilds.
  CompilerService? _compilerService;
  EditorRunController? _runController;

  @override
  void initState() {
    super.initState();
    _codeController = CppEditorController();
    _editorFocusNode.addListener(_onEditorFocusChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeFile());
  }

  /// The shell passes a new [EditorScreen.initialFileId] when a file is
  /// opened from Home / Files / Examples. The State is kept alive, so
  /// without this the editor would keep showing the previous file.
  @override
  void didUpdateWidget(covariant EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.initialFileId;
    if (id == null || id == _openFileId) return;

    // Flush an unsaved edit of the file we are leaving.
    final leavingId = _openFileId;
    if (leavingId != null && (_autosaveDebounce?.isActive ?? false)) {
      _autosaveDebounce!.cancel();
      context.read<FileRepository>().updateContent(leavingId, _codeController.text);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openFileFromRepo(id);
    });
  }

  /// Called when the keyboard opens/closes. MediaQuery can't be used for
  /// this: the enclosing Scaffold consumes the keyboard inset and reports 0
  /// to its children, so we listen to the window metrics directly.
  @override
  void didChangeMetrics() {
    if (mounted) setState(() {});
  }

  void _onEditorFocusChanged() {
    if (mounted) setState(() {}); // Re-evaluate which panels fit on screen.
  }

  void _setFullscreen(bool value) {
    if (_fullscreen == value) return;
    setState(() => _fullscreen = value);
    UiState.editorFullscreen.value = value;
    if (value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
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
    // In full-screen mode there is no output panel, so show it as a sheet.
    if (_fullscreen && mounted) _showOutputSheet();
  }

  void _showOutputSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: IdeColors.darkSurface,
      builder: (sheetContext) {
        return ChangeNotifierProvider<EditorRunController>.value(
          value: _runController!,
          child: Consumer<EditorRunController>(
            builder: (context, run, _) => OutputConsole(
              status: run.status,
              compileResult: run.lastCompileResult,
              runResult: run.lastRunResult,
              onClear: run.clear,
              onErrorTap: (line) {
                Navigator.of(sheetContext).pop();
                _jumpToErrorLine(line);
              },
            ),
          ),
        );
      },
    );
  }

  void _showInputSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IdeColors.darkSurface,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: InputPanel(
            controller: _stdinController,
            onRunWithInput: () {
              Navigator.of(sheetContext).pop();
              _run();
            },
          ),
        );
      },
    );
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
    WidgetsBinding.instance.removeObserver(this);
    _editorFocusNode.removeListener(_onEditorFocusChanged);
    _editorFocusNode.dispose();
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    if (_compilerService is ApiCompilerService) {
      (_compilerService as ApiCompilerService).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsRepository>().settings;

    // With the soft keyboard open there is very little vertical room left,
    // so drop the panels that aren't needed while typing. Otherwise the code
    // editor is squeezed to almost nothing on phones.
    final view = View.of(context);
    final keyboardOpen = view.viewInsets.bottom / view.devicePixelRatio > 0;
    final editorTyping = keyboardOpen && _editorFocusNode.hasFocus;
    final showInputPanel = !_fullscreen && !editorTyping;
    final showOutputPanel = !_fullscreen && !keyboardOpen;

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
          return PopScope(
            canPop: !_fullscreen,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) _setFullscreen(false);
            },
            child: Scaffold(
            appBar: _fullscreen
                ? null
                : AppBar(
              title: Text(_openFile!.name, style: const TextStyle(fontFamily: AppTheme.editorFontFamily)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  tooltip: 'Full screen editor',
                  onPressed: () => _setFullscreen(true),
                ),
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
                  if (_fullscreen)
                    _buildFullscreenBar(run)
                  else
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
                  if (!_fullscreen || keyboardOpen)
                    EditorAccessoryBar(controller: _codeController, focusNode: _editorFocusNode),
                  if (showInputPanel) InputPanel(controller: _stdinController, onRunWithInput: _run),
                  if (showOutputPanel)
                    OutputConsole(
                      status: run.status,
                      compileResult: run.lastCompileResult,
                      runResult: run.lastRunResult,
                      onClear: run.clear,
                      onErrorTap: _jumpToErrorLine,
                    ),
                  if (!_fullscreen) _buildActionBar(run),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }

  /// Slim top strip shown instead of the app bar + toolbar in full-screen
  /// mode: exit, file name, search, program input and Run.
  Widget _buildFullscreenBar(EditorRunController run) {
    return Container(
      height: 44,
      color: IdeColors.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit, size: 22, color: IdeColors.darkTextPrimary),
            tooltip: 'Exit full screen',
            onPressed: () => _setFullscreen(false),
          ),
          Expanded(
            child: Text(
              _openFile!.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.editorFontFamily,
                fontSize: 13,
                color: IdeColors.darkTextPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, size: 20, color: IdeColors.darkTextPrimary),
            tooltip: 'Search / Replace',
            onPressed: () => showSearchReplaceSheet(context, _codeController),
          ),
          IconButton(
            icon: const Icon(Icons.input, size: 20, color: IdeColors.darkTextPrimary),
            tooltip: 'Program input',
            onPressed: _showInputSheet,
          ),
          if (run.isBusy)
            const SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: IdeColors.accent),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 26, color: IdeColors.success),
              tooltip: 'Run',
              onPressed: _run,
            ),
        ],
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
