

/// Model class representing an image file retrieved from the device.
class ImageModel {
  /// Unique identifier for the image.
  final int id;

  /// Name of the image file (e.g., "photo.jpg").
  final String name;

  /// File system path to the image (e.g., "/storage/emulated/0/Pictures/photo.jpg").
  final String? path;

  /// Content URI for the image (e.g., "content://media/external/images/media/123").
  final String uri;

  /// Size of the image in bytes.
  final int size;

  /// Date the image was added (milliseconds since epoch).
  final int dateAdded;

  /// Date the image was last modified (milliseconds since epoch).
  final int dateModified;

  /// Width of the image in pixels.
  final int width;

  /// Height of the image in pixels.
  final int height;

  /// MIME type of the image (e.g., "image/jpeg").
  final String mimeType;

  /// File extension (e.g., "jpg", "png").
  final String? fileExtension;

  ImageModel({
    int? id,
    String? name,
    this.path,
    String? uri,
    int? size,
    int? dateAdded,
    int? dateModified,
    int? width,
    int? height,
    String? mimeType,
    this.fileExtension,
  })  : id = id ?? 0,
        name = name ?? 'Unknown',
        uri = uri ?? '',
        size = size ?? 0,
        dateAdded = dateAdded ?? 0,
        dateModified = dateModified ?? 0,
        width = width ?? 0,
        height = height ?? 0,
        mimeType = mimeType ?? 'image/*';

  /// Creates an ImageModel from a map returned by the native platform.
  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? 'Unknown',
      path: map['path'] as String?,
      uri: map['uri'] as String? ?? '',
      size: map['size'] as int? ?? 0,
      dateAdded: map['dateAdded'] as int? ?? 0,
      dateModified: map['dateModified'] as int? ?? 0,
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
      mimeType: map['mimeType'] as String? ?? 'image/*',
      fileExtension: map['fileExtension'] as String?,
    );
  }

  /// Converts the ImageModel to a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'uri': uri,
      'size': size,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'width': width,
      'height': height,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
    };
  }
}