// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'package:media_getter/models/fileModel.dart';
import 'package:media_getter/models/videoModel.dart';

import 'media_getter_method_channel.dart';
import 'media_getter_platform_interface.dart';
import 'models/imageModel.dart';

class MediaGetter {
  Future<String?> getPlatformVersion() {
    return media_getterPlatform.instance.getPlatformVersion();
  }

  // 1
  Future<List<ImageModel>> getAllImages({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) {
    return media_getterPlatform.instance.getAllImages(
      fromDate: fromDate,
      limit: limit,
      orderByDesc: orderByDesc,
    );
  }

  // 2
  Future<List<VideoModel>> getAllVideos({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) {
    return media_getterPlatform.instance.getAllVideos(
      fromDate: fromDate,
      limit: limit,
      orderByDesc: orderByDesc,
    );
  }

  // 3
  Future<List<FileModel>> getAllFiles({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
    List<String> fileExtensions = const ['pdf', 'txt', 'zip'],
  }) {
    return media_getterPlatform.instance.getAllFiles(
      fromDate: fromDate,
      limit: limit,
      orderByDesc: orderByDesc,
      fileExtensions: fileExtensions,
    );
  }

  // 4
  Future<List<FileModel>> getDownloadFolderItems({
    DateTime? fromDate,
    int? limit,
    bool orderByDesc = true,
  }) {
    return media_getterPlatform.instance.getDownloadFolderItems(
      fromDate: fromDate,
      limit: limit,
      orderByDesc: orderByDesc,
    );
  }

  // 5
  Future showToast(String message, {ToastLength length = ToastLength.short}) {
    return media_getterPlatform.instance.showToast(message, length: length);
  }

  // 6
  // Future<bool> openFile({required String filePath}) {
  //   return media_getterPlatform.instance.openFile(filePath: filePath);
  // }

  // 7
  Future<bool> deleteFile({required String filePath}) {
    return media_getterPlatform.instance.deleteFile(filePath: filePath);
  }
}
