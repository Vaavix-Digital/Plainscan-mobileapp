class FileModel {
  final String id;
  final String name;
  final DateTime createdDate;
  final double sizeKb;
  final String fileType;
  final String? path;
  final bool isFavorite;
  final String? sourceFileId;
  final List<String>? sourceFileIds;

  const FileModel({
    required this.id,
    required this.name,
    required this.createdDate,
    required this.sizeKb,
    required this.fileType,
    this.path,
    this.isFavorite = false,
    this.sourceFileId,
    this.sourceFileIds,
  });

  FileModel copyWith({
    String? name,
    bool? isFavorite,
    DateTime? createdDate,
    double? sizeKb,
    String? fileType,
    String? path,
    String? sourceFileId,
    List<String>? sourceFileIds,
  }) {
    return FileModel(
      id: id,
      name: name ?? this.name,
      createdDate: createdDate ?? this.createdDate,
      sizeKb: sizeKb ?? this.sizeKb,
      fileType: fileType ?? this.fileType,
      path: path ?? this.path,
      isFavorite: isFavorite ?? this.isFavorite,
      sourceFileId: sourceFileId ?? this.sourceFileId,
      sourceFileIds: sourceFileIds ?? this.sourceFileIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdDate': createdDate.toIso8601String(),
        'sizeKb': sizeKb,
        'fileType': fileType,
        'path': path,
        'isFavorite': isFavorite,
        if (sourceFileId != null) 'sourceFileId': sourceFileId,
        if (sourceFileIds != null) 'sourceFileIds': sourceFileIds,
      };

  factory FileModel.fromJson(Map<String, dynamic> json) => FileModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdDate: json['createdDate'] != null
            ? DateTime.tryParse(json['createdDate'] as String) ?? DateTime.now()
            : DateTime.now(),
        sizeKb: (json['sizeKb'] as num?)?.toDouble() ?? 0.0,
        fileType: json['fileType'] as String? ?? 'PDF',
        path: json['path'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
        sourceFileId: json['sourceFileId'] as String?,
        sourceFileIds: (json['sourceFileIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
}
