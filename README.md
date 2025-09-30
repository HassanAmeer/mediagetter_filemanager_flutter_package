# media_getter
- Like for filemanager  

A Flutter plugin for accessing media and files on Android devices using method channels. It provides a simple interface to retrieve images, videos, and other files, along with their metadata, and supports actions like opening and deleting files.

## Features

- Retrieve all images, videos, and files from Android device storage.
- Access comprehensive metadata for media and files:
  - D, Name, Path, URI: Unique identifier, file name, file system path, and content URI.
  - Size and Dimensions: File size (bytes) and image/video dimensions (width/height)
  - Dates: Creation and modification timestamps.
  - Creation and modification dates
  - MIME Type and Extension: File type (e.g., image/jpeg, application/pdf) and extension (e.g., jpg, pdf).
- Fetch files from the Download folder.
- Delete files from storage (requires appropriate permissions).
- Display native Android toast notifications.

### Screenshots
 <img src="https://github.com/HassanAmeer/mediagetter_filemanager_flutter_package/blob/main/screenshots/demo.png?raw=true" style="width:50%">
 [![Media getter Demo](https://github.com/HassanAmeer/mediagetter_filemanager_flutter_package/blob/main/screenshots/demo.png?raw=true)](https://github.com/HassanAmeer/mediagetter_filemanager_flutter_package/)
 <hr>


### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  media_getter: ^0.0.1
```


## Platform Support

- ✅ Android
- ❌ iOS (not implemented)

## example usage

### 1. request a permissions thats you need
```dart
  getPermissions() async {
    // Request permissions based on Android version
    // by adding this package
    // import 'package:permission_handler/permission_handler.dart';

    Map<Permission, PermissionStatus> statuses = await [
      // 1. 👉🏻 if need all types of file permssions
      Permission.manageExternalStorage, // For non-media files (Android 11+)
      //2.  👉🏻 others wise for specific permissions
      Permission.storage, // For Android 12 and below
      Permission.photos, // For images (Android 13+)
      Permission.videos, // For videos (Android 13+)
      Permission.audio, // For audio (Android 13+)
    ].request();


    // 1. 👉🏻 if need all types of file permssions
    bool hasFullAccess =
        statuses[Permission.manageExternalStorage]?.isGranted ?? true;

    // Check if all required permissions are granted
    // 2. 👉🏻 others wise for specific permissions
    bool hasStorageAccess = statuses[Permission.storage]?.isGranted ?? false;
    bool hasMediaAccess =
        statuses[Permission.photos]?.isGranted ??
        true && statuses[Permission.videos]!.isGranted ??
        true && statuses[Permission.audio]!.isGranted ??
        true;

    if (!hasStorageAccess && !hasMediaAccess && !hasFullAccess) {
      debugPrint("Required permissions denied");
      await media_getter().showToast(
        "Please grant storage permissions",
        length: ToastLength.long,
      );
      return;
    }
  }
```

### 2. get files thast you need 
- now call any media function thats you need 
```dart
 onPressed: () async {
          var check = await media_getter().getAllImages(
            orderByDesc: true,
            // limit: 1,
            fromDate: DateTime.now().subtract(const Duration(days: 1)),
          );
          debugPrint(
            "👉🏻 getAllImages ${check.map((e) => e.path).toString()}",
          );

          final limitedVideos = await media_getter().getAllVideos();
          debugPrint(
            "👉🏻 limitedVideos ${limitedVideos.map((e) => e.path).toString()}",
          );

          final getFiles = await media_getter().getAllFiles(
            fileExtensions: ['pdf', 'txt', 'mp4', 'mp3', 'jpg', 'wav'],
          );
          debugPrint("👉🏻 getFiles ${getFiles.map((e) => e.path).toString()}");

          final getDownloadedFiles = await media_getter()
              .getDownloadFolderItems();
          debugPrint(
            "👉🏻 getDownloadedFiles ${getDownloadedFiles.map((e) => e.path).toString()}",
          );

          // if (getFiles.isNotEmpty) {
          //   final path = getFiles.first.path ?? getFiles.first.uri;
          //   // Delete file
          //   final deleted = await media_getter().deleteFile(filePath: path);
          //   print("File deleted: $deleted");
          // }

          await media_getter().showToast(
            "Found ${getDownloadedFiles.length} files",
            length: ToastLength.short,
          );
        },
```
### print result
```bash
    I/flutter (10376): 👉🏻 getAllImages (/storage/emulated/0/Download/images.png)
    I/flutter (10376): 👉🏻 limitedVideos (/storage/emulated/0/Download/file_example_MP4_480_1_5MG.mp4)
    I/flutter (10376): 👉🏻 media_getter method channel  getAllFiles fileExtensions: [pdf, txt, mp4, mp3, jpg, wav], limit:null,orderByDesc:true 
    I/flutter (10376): 👉🏻 getFiles (/storage/emulated/0/Documents/Get_Started_With_Smallpdf.pdf, /storage/emulated/0/Download/file_example_MP4_480_1_5MG.mp4, /storage/emulated/0/Download/file_example_MP3_1MG (1).mp3, /storage/emulated/0/Download/file_example_MP3_1MG.mp3, /storage/emulated/0/Download/Get_Started_With_Smallpdf.pdf)
    I/flutter (10376): 👉🏻 getDownloadedFiles (/storage/emulated/0/Download/images.png, /storage/emulated/0/Download/sample-large-zip-file.zip, /storage/emulated/0/Download/sample-zip-file.zip, ..., /storage/emulated/0/Download/images.jpeg, /storage/emulated/0/Download/download.png)
```
# ScreenShot
 [![Media getter Demo](screenshots/demo.png?raw=true)](https://github.com/HassanAmeer/mediagetter_filemanager_flutter_package/)
