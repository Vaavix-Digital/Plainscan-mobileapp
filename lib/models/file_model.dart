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
  }) {
    return FileModel(
      id: id,
      name: name ?? this.name,
      createdDate: createdDate,
      sizeKb: sizeKb,
      fileType: fileType,
      path: path,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
