import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/constants/cpp_templates.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/file_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/file_card/file_card.dart';
import '../files/new_file_dialog.dart';

class HomeScreen extends StatelessWidget {
  final void Function(String fileId) onOpenFile;

  const HomeScreen({super.key, required this.onOpenFile});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _createFile(BuildContext context) async {
    final result = await showNewFileDialog(context);
    if (result == null) return;

    final repo = context.read<FileRepository>();
    final template = CppTemplates.all[result.templateName] ?? CppTemplates.blank;
    final file = await repo.createFile(name: result.fileName, content: template);
    if (context.mounted) onOpenFile(file.id);
  }

  @override
  Widget build(BuildContext context) {
    final fileRepo = context.watch<FileRepository>();
    final settings = context.watch<SettingsRepository>().settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('C++ IDE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search files',
            onPressed: () => showSearch(context: context, delegate: _FileSearchDelegate(fileRepo, onOpenFile)),
          ),
        ],
      ),
      body: fileRepo.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fileRepo.load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('${_greeting()} 👋', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  _CompilerStatusBadge(endpoint: settings.compilerApiUrl),
                  const SizedBox(height: 20),
                  Text('Recent Files', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (fileRepo.recentFiles.isEmpty)
                    const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'No C++ files yet',
                      message: 'Create your first C++ program to get started.',
                    )
                  else
                    ...fileRepo.recentFiles.map(
                      (f) => FileCard(file: f, onTap: () => onOpenFile(f.id)),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _createFile(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New C++ File'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

enum _CompilerStatus { checking, online, offline }

class _CompilerStatusBadge extends StatefulWidget {
  final String endpoint;
  const _CompilerStatusBadge({required this.endpoint});

  @override
  State<_CompilerStatusBadge> createState() => _CompilerStatusBadgeState();
}

class _CompilerStatusBadgeState extends State<_CompilerStatusBadge> {
  _CompilerStatus _status = _CompilerStatus.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant _CompilerStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endpoint != widget.endpoint) {
      setState(() => _status = _CompilerStatus.checking);
      _check();
    }
  }

  Future<void> _check() async {
    try {
      final uri = Uri.parse('${widget.endpoint}/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (!mounted) return;
      setState(() => _status = response.statusCode == 200 ? _CompilerStatus.online : _CompilerStatus.offline);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _CompilerStatus.offline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (Color dotColor, String label) = switch (_status) {
      _CompilerStatus.checking => (IdeColors.darkTextSecondary, 'Checking…'),
      _CompilerStatus.online => (IdeColors.success, 'Connected'),
      _CompilerStatus.offline => (IdeColors.danger, 'Unreachable'),
    };

    return InkWell(
      onTap: _check,
      borderRadius: BorderRadius.circular(IdeMetrics.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: IdeColors.darkSurfaceAlt,
          borderRadius: BorderRadius.circular(IdeMetrics.radiusSm),
          border: Border.all(color: IdeColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 8, color: dotColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: dotColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.endpoint,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: IdeColors.darkTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileSearchDelegate extends SearchDelegate<void> {
  final FileRepository repo;
  final void Function(String fileId) onOpenFile;

  _FileSearchDelegate(this.repo, this.onOpenFile);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  Widget _results(BuildContext context) {
    final matches = repo.files.where((f) => f.name.toLowerCase().contains(query.toLowerCase())).toList();
    if (matches.isEmpty) {
      return const EmptyState(icon: Icons.search_off, title: 'No matches', message: 'Try a different file name.');
    }
    return ListView(
      children: matches
          .map((f) => FileCard(
                file: f,
                onTap: () {
                  close(context, null);
                  onOpenFile(f.id);
                },
              ))
          .toList(),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
}
