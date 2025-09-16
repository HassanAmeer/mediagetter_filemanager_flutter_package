class FileModel {
  final int id;
  final String name;
  final String? path;
  final String uri;
  final int size;
  final DateTime dateAdded;
  final DateTime dateModified;
  final String mimeType;
  final String? fileExtension;

  FileModel({
    required this.id,
    required this.name,
    this.path,
    required this.uri,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    required this.mimeType,
    this.fileExtension,
  });

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      path: map['path'],
      uri: map['uri'] ?? '',
      size: map['size']?.toInt() ?? 0,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['dateAdded']?.toInt() ?? 0),
      dateModified: DateTime.fromMillisecondsSinceEpoch(map['dateModified']?.toInt() ?? 0),
      mimeType: map['mimeType'] ?? '',
      fileExtension: map['fileExtension'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'uri': uri,
      'size': size,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'dateModified': dateModified.millisecondsSinceEpoch,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
    };
  }

  // Helper method to get file size in human readable format
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  @override
  String toString() {
    return 'FileModel(id: $id, name: $name, path: $path, uri: $uri, size: $size, dateAdded: $dateAdded, dateModified: $dateModified, mimeType: $mimeType, fileExtension: $fileExtension)';
  }
}
