import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/cpp_templates.dart';
import '../models/cpp_file.dart';
import '../services/file_storage_service.dart';

/// Owns the list of C++ files, recent-file ordering, and the currently
/// remembered "last open" file — all persisted locally. Widgets never talk
/// to [FileStorageService] directly.
class FileRepository extends ChangeNotifier {
  final FileStorageService _storage;
  final _uuid = const Uuid();

  List<CppFile> _files = [];
  List<String> _recentIds = [];
  String? _lastOpenFileId;
  bool _isLoading = true;

  FileRepository({FileStorageService? storage}) : _storage = storage ?? FileStorageService();

  bool get isLoading => _isLoading;
  List<CppFile> get files => List.unmodifiable(_files);
  String? get lastOpenFileId => _lastOpenFileId;

  List<CppFile> get recentFiles {
    final byId = {for (final f in _files) f.id: f};
    return _recentIds.map((id) => byId[id]).whereType<CppFile>().toList();
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _files = await _storage.loadFiles();
    _recentIds = await _storage.loadRecentIds();
    _lastOpenFileId = await _storage.loadLastOpenFileId();

    if (_files.isEmpty) {
      // First launch: seed with a friendly starter file rather than an
      // empty one — an empty source fails "no main function" the moment
      // someone hits Compile, which is a confusing first impression.
      final seed = CppFile(
        id: _uuid.v4(),
        name: 'main${AppConfig.cppExtension}',
        content: CppTemplates.helloWorld,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      _files = [seed];
      await _storage.saveFiles(_files);
    }

    _isLoading = false;
    notifyListeners();
  }

  CppFile? byId(String id) {
    for (final f in _files) {
      if (f.id == id) return f;
    }
    return null;
  }

  bool _nameExists(String name, {String? excludingId}) {
    return _files.any((f) => f.name == name && f.id != excludingId);
  }

  String _uniqueName(String baseName) {
    var candidate = baseName;
    var counter = 1;
    while (_nameExists(candidate)) {
      counter++;
      final withoutExt = baseName.replaceAll(AppConfig.cppExtension, '');
      candidate = '$withoutExt$counter${AppConfig.cppExtension}';
    }
    return candidate;
  }

  Future<CppFile> createFile({required String name, required String content}) async {
    var safeName = name.trim();
    if (!safeName.endsWith(AppConfig.cppExtension)) {
      safeName = '$safeName${AppConfig.cppExtension}';
    }
    safeName = _uniqueName(safeName);

    final file = CppFile(
      id: _uuid.v4(),
      name: safeName,
      content: content,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    _files = [..._files, file];
    await _storage.saveFiles(_files);
    notifyListeners();
    return file;
  }

  Future<void> renameFile(String id, String newName) async {
    var safeName = newName.trim();
    if (!safeName.endsWith(AppConfig.cppExtension)) {
      safeName = '$safeName${AppConfig.cppExtension}';
    }
    if (_nameExists(safeName, excludingId: id)) {
      safeName = _uniqueName(safeName);
    }

    _files = _files
        .map((f) => f.id == id ? f.copyWith(name: safeName, modifiedAt: DateTime.now()) : f)
        .toList();
    await _storage.saveFiles(_files);
    notifyListeners();
  }

  Future<void> updateContent(String id, String content) async {
    _files = _files
        .map((f) => f.id == id ? f.copyWith(content: content, modifiedAt: DateTime.now()) : f)
        .toList();
    await _storage.saveFiles(_files);
    notifyListeners();
  }

  Future<void> deleteFile(String id) async {
    _files = _files.where((f) => f.id != id).toList();
    _recentIds = _recentIds.where((rid) => rid != id).toList();
    if (_lastOpenFileId == id) _lastOpenFileId = null;

    await _storage.saveFiles(_files);
    await _storage.saveRecentIds(_recentIds);
    await _storage.saveLastOpenFileId(_lastOpenFileId);
    notifyListeners();
  }

  Future<CppFile> duplicateFile(String id) async {
    final original = byId(id);
    if (original == null) {
      throw StateError('Cannot duplicate: file not found');
    }
    final baseName = original.name.replaceAll(AppConfig.cppExtension, '');
    return createFile(name: '${baseName}_copy', content: original.content);
  }

  Future<void> markOpened(String id) async {
    _lastOpenFileId = id;
    _recentIds = [id, ..._recentIds.where((rid) => rid != id)];
    if (_recentIds.length > 10) {
      _recentIds = _recentIds.sublist(0, 10);
    }
    await _storage.saveRecentIds(_recentIds);
    await _storage.saveLastOpenFileId(id);
    notifyListeners();
  }
}
