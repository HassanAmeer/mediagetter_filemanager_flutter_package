class VideoModel {
  final int id;
  final String name;
  final String? path;
  final String uri;
  final int size;
  final DateTime dateAdded;
  final DateTime dateModified;
  final int duration; // Duration in milliseconds
  final int width;
  final int height;
  final String mimeType;
  final String? fileExtension; // Added field


  VideoModel({
    required this.id,
    required this.name,
    this.path,
    required this.uri,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    required this.duration,
    required this.width,
    required this.height,
    required this.mimeType,
    this.fileExtension,

  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      path: map['path'],
      uri: map['uri'] ?? '',
      size: map['size']?.toInt() ?? 0,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['dateAdded']?.toInt() ?? 0),
      dateModified: DateTime.fromMillisecondsSinceEpoch(map['dateModified']?.toInt() ?? 0),
      duration: map['duration']?.toInt() ?? 0,
      width: map['width']?.toInt() ?? 0,
      height: map['height']?.toInt() ?? 0,
      mimeType: map['mimeType'] ?? '',
      fileExtension: map['fileExtension'] as String?,

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
      'duration': duration,
      'width': width,
      'height': height,
      'mimeType': mimeType,

    };
  }

  @override
  String toString() {
    return 'VideoModel(id: $id, name: $name, path: $path, uri: $uri, size: $size, dateAdded: $dateAdded, dateModified: $dateModified, duration: $duration, width: $width, height: $height, mimeType: $mimeType)';
  }
}