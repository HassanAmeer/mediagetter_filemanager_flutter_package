import 'package:mediagetter/models/fileModel.dart';
import 'package:mediagetter/models/videoModel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'media_getter_method_channel.dart';
import 'models/imageModel.dart';

abstract class media_getterPlatform extends PlatformInterface {
  /// Constructs a media_getterPlatform.
  media_getterPlatform() : super(token: _token);

  static final Object _token = Object();

  static media_getterPlatform _instance = MethodChannelmedia_getter();

  /// The default instance of [media_getterPlatform] to use.
  ///
  /// Defaults to [MethodChannelmedia_getter].
  static media_getterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [media_getterPlatform] when
  /// they register themselves.
  static set instance(media_getterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<ImageModel>> getAllImages({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) {
    throw UnimplementedError('getAllImages() has not been implemented.');
  }

  Future<List<VideoModel>> getAllVideos({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) {
    throw UnimplementedError('getAllVideos() has not been implemented.');
  }

  Future<List<FileModel>> getAllFiles({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
    List<String> fileExtensions = const ['pdf', 'txt', 'zip'],
  }) {
    throw UnimplementedError('getAllFiles() has not been implemented.');
  }

  Future<List<FileModel>> getDownloadFolderItems({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) {
    throw UnimplementedError(
      'getDownloadFolderItems() has not been implemented.',
    );
  }

  Future<void> showToast(
    String message, {
    ToastLength length = ToastLength.short,
  }) {
    throw UnimplementedError(
      'getDownloadFolderItemsshowToast has not been implemented.',
    );
  }

  /// Opens a file using its path via the native platform.
  // Future<bool> openFile({required String filePath});

  /// Deletes a file using its path via the native platform.
  Future<bool> deleteFile({required String filePath});
}
