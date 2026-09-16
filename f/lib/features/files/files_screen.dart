import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/cpp_templates.dart';
import '../../data/repositories/file_repository.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/file_card/file_card.dart';
import 'new_file_dialog.dart';

class FilesScreen extends StatelessWidget {
  final void Function(String fileId) onOpenFile;

  const FilesScreen({super.key, required this.onOpenFile});

  Future<void> _createFile(BuildContext context) async {
    final result = await showNewFileDialog(context);
    if (result == null) return;
    final repo = context.read<FileRepository>();
    final template = CppTemplates.all[result.templateName] ?? CppTemplates.blank;
    final file = await repo.createFile(name: result.fileName, content: template);
    if (context.mounted) onOpenFile(file.id);
  }

  Future<void> _rename(BuildContext context, String id, String currentName) async {
    final controller = TextEditingController(text: currentName.replaceAll('.cpp', ''));
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename file'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(suffixText: '.cpp')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Rename')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && context.mounted) {
      await context.read<FileRepository>().renameFile(id, newName);
    }
  }

  Future<void> _delete(BuildContext context, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('This will permanently delete $name.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<FileRepository>().deleteFile(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FileRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Project')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createFile(context),
        child: const Icon(Icons.add),
      ),
      body: repo.isLoading
          ? const Center(child: CircularProgressIndicator())
          : repo.files.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open,
                  title: 'No C++ files yet',
                  message: 'Create your first C++ program to get started.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: repo.files.length,
                  itemBuilder: (context, index) {
                    final file = repo.files[index];
                    return FileCard(
                      file: file,
                      onTap: () => onOpenFile(file.id),
                      onRename: () => _rename(context, file.id, file.name),
                      onDelete: () => _delete(context, file.id, file.name),
                      onDuplicate: () => repo.duplicateFile(file.id),
                    );
                  },
                ),
    );
  }
}
