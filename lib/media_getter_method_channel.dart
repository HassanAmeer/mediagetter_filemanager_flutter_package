import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'media_getter_platform_interface.dart';
import 'models/fileModel.dart';
import 'models/imageModel.dart';
import 'models/videoModel.dart';

// Enum for toast length
enum ToastLength { short, long }

/// Implementation of [media_getterPlatform] using method channels to communicate with native Android.
class MethodChannelmedia_getter extends media_getterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('media_getter');

  /// Gets the platform version (e.g., Android version).
  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  /// Fetches all images from the device with optional filters.
  @override
  Future<List<ImageModel>> getAllImages({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) async {
    // Prepare arguments for the native method call
    final Map<String, dynamic> arguments = {
      'fromDate': fromDate?.millisecondsSinceEpoch,
      'limit': limit,
      'orderByDesc': orderByDesc,
    };

    // Invoke the native method to get images
    final result = await methodChannel.invokeMethod<List>(
      'getAllImages',
      arguments,
    );
    debugPrint("👉🏻 getAllImages result: $result");

    // Return empty list if result is null
    if (result == null) return [];

    // Convert native result to ImageModel objects
    var convertedIntoModel = result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return ImageModel.fromMap(map);
    }).toList();

    return convertedIntoModel;
  }

  /// Fetches all videos from the device with optional filters.
  @override
  Future<List<VideoModel>> getAllVideos({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) async {
    // Prepare arguments for the native method call
    final Map<String, dynamic> arguments = {
      'fromDate': fromDate?.millisecondsSinceEpoch,
      'limit': limit,
      'orderByDesc': orderByDesc,
    };

    // Invoke the native method to get videos
    final result = await methodChannel.invokeMethod<List>(
      'getAllVideos',
      arguments,
    );
    debugPrint("👉🏻 getAllVideos result: $result");

    // Return empty list if result is null
    if (result == null) return [];

    // Convert native result to VideoModel objects
    var convertedIntoModel = result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return VideoModel.fromMap(map);
    }).toList();

    return convertedIntoModel;
  }

  /// Fetches all files with specified extensions from the device.
  @override
  Future<List<FileModel>> getAllFiles({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
    List<String> fileExtensions = const ['pdf', 'txt', 'zip'],
  }) async {
    debugPrint(
      "👉🏻 getAllFiles fileExtensions: $fileExtensions, limit: $limit, orderByDesc: $orderByDesc",
    );

    // Validate fileExtensions
    if (fileExtensions.isEmpty) {
      throw ArgumentError('fileExtensions cannot be empty');
    }

    // Prepare arguments for the native method call
    final Map<String, dynamic> arguments = {
      'fromDate': fromDate?.millisecondsSinceEpoch,
      'limit': limit,
      'orderByDesc': orderByDesc,
      'fileExtensions': fileExtensions,
    };

    // Invoke the native method to get files
    final result = await methodChannel.invokeMethod<List>(
      'getAllFiles',
      arguments,
    );

    // Return empty list if result is null
    if (result == null) return [];

    // Convert native result to FileModel objects
    var convertedIntoModel = result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return FileModel.fromMap(map);
    }).toList();

    return convertedIntoModel;
  }

  /// Fetches files from the Download folder with optional filters.
  @override
  Future<List<FileModel>> getDownloadFolderItems({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) async {
    // Prepare arguments for the native method call
    final Map<String, dynamic> arguments = {
      'fromDate': fromDate?.millisecondsSinceEpoch,
      'limit': limit,
      'orderByDesc': orderByDesc,
    };

    // Invoke the native method to get Download folder files
    final result = await methodChannel.invokeMethod<List>(
      'getDownloadFolderItems',
      arguments,
    );

    // Return empty list if result is null
    if (result == null) return [];

    // Convert native result to FileModel objects
    var convertedIntoModel = result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return FileModel.fromMap(map);
    }).toList();

    return convertedIntoModel;
  }

  /// Shows a native Android toast with the specified message and duration.
  @override
  Future<void> showToast(
    String message, {
    ToastLength length = ToastLength.short,
  }) async {
    final Map<String, dynamic> arguments = {
      'message': message,
      'length': length == ToastLength.short ? 'short' : 'long',
    };

    await methodChannel.invokeMethod('showToast', arguments);
  }

  /// Opens a file using its path via the native platform.
  // @override
  // Future<bool> openFile({required String filePath}) async {
  //   try {
  //     // Invoke the native method to open the file
  //     final result = await methodChannel.invokeMethod<bool>('openFile', {'path': filePath});
  //     return result ?? false;
  //   } catch (e) {
  //     debugPrint("👉🏻 openFile error: $e");
  //     return false;
  //   }
  // }

  /// Deletes a file using its path via the native platform.
  @override
  Future<bool> deleteFile({required String filePath}) async {
    try {
      // Invoke the native method to delete the file
      final result = await methodChannel.invokeMethod<bool>('deleteFile', {
        'path': filePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint("👉🏻 deleteFile error: $e");
      return false;
    }
  }
}
