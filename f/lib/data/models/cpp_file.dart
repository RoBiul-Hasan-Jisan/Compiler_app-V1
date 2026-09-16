/// A single .cpp source file managed by the app.
class CppFile {
  final String id;
  final String name; // includes the .cpp extension
  final String content;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const CppFile({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.modifiedAt,
  });

  CppFile copyWith({
    String? name,
    String? content,
    DateTime? modifiedAt,
  }) {
    return CppFile(
      id: id,
      name: name ?? this.name,
      content: content ?? this.content,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
      };

  factory CppFile.fromJson(Map<String, dynamic> json) => CppFile(
        id: json['id'] as String,
        name: json['name'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      );
}
