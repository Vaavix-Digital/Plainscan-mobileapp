class FileModel {
  final String id;
  final String name;
  final DateTime createdDate;
  final double sizeKb;
  final String fileType;
  final String? path;
  final bool isFavorite;

  const FileModel({
    required this.id,
    required this.name,
    required this.createdDate,
    required this.sizeKb,
    required this.fileType,
    this.path,
    this.isFavorite = false,
  });

  FileModel copyWith({
    String? name,
    bool? isFavorite,
    DateTime? createdDate,
    double? sizeKb,
    String? fileType,
    String? path,
  }) {
    return FileModel(
      id: id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      sizeKb: sizeKb ?? this.sizeKb,
      fileType: fileType ?? this.fileType,
      path: path ?? this.path,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
