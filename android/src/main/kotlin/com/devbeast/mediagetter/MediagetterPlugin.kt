package com.devbeast.mediagetter

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class MediagetterPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(
      @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  ) {
    // Initialize method channel and context
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mediagetter")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getAllImages" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fromDate = call.argument<Long?>("fromDate")
            val limit = call.argument<Int?>("limit")
            val orderByDesc = call.argument<Boolean>("orderByDesc") ?: true

            val images = getAllImagesFromDevice(fromDate, limit, orderByDesc)
            withContext(Dispatchers.Main) { result.success(images) }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              android.util.Log.e("MediagetterPlugin", "Failed to get images: ${e.message}", e)
              result.error("ERROR", "Failed to get images: ${e.message}", null)
            }
          }
        }
      }
      "getAllVideos" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fromDate = call.argument<Long?>("fromDate")
            val limit = call.argument<Int?>("limit")
            val orderByDesc = call.argument<Boolean>("orderByDesc") ?: true

            val videos = getAllVideosFromDevice(fromDate, limit, orderByDesc)
            withContext(Dispatchers.Main) { result.success(videos) }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              android.util.Log.e("MediagetterPlugin", "Failed to get videos: ${e.message}", e)
              result.error("ERROR", "Failed to get videos: ${e.message}", null)
            }
          }
        }
      }
      "getAllFiles" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fromDate = call.argument<Long?>("fromDate")
            val limit = call.argument<Int?>("limit")
            val orderByDesc = call.argument<Boolean>("orderByDesc") ?: true
            val fileExtensions = call.argument<List<String>?>("fileExtensions")

            val files = getAllFilesFromDevice(fromDate, limit, orderByDesc, fileExtensions)
            withContext(Dispatchers.Main) { result.success(files) }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              android.util.Log.e("MediagetterPlugin", "Failed to get files: ${e.message}", e)
              result.error("ERROR", "Failed to get files: ${e.message}", null)
            }
          }
        }
      }
      "getDownloadFolderItems" -> {
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val fromDate = call.argument<Long?>("fromDate")
            val limit = call.argument<Int?>("limit")
            val orderByDesc = call.argument<Boolean>("orderByDesc") ?: true

            val files = getDownloadFolderItems(fromDate, limit, orderByDesc)
            withContext(Dispatchers.Main) { result.success(files) }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              android.util.Log.e(
                "MediagetterPlugin",
                "Failed to get download folder items: ${e.message}",
                e
              )
              result.error("ERROR", "Failed to get download folder items: ${e.message}", null)
            }
          }
        }
      }
      "showToast" -> {
        val message = call.argument<String>("message") ?: ""
        val length = call.argument<String>("length") ?: "short"
        val duration = if (length == "long") Toast.LENGTH_LONG else Toast.LENGTH_SHORT

        Toast.makeText(context, message, duration).show()
        result.success(null)
      }
      "deleteFile" -> {
        val path = call.argument<String>("path")
        if (path == null) {
          result.error("INVALID_PATH", "File path cannot be null", null)
          return
        }
        CoroutineScope(Dispatchers.IO).launch {
          try {
            val success = deleteFile(path)
            withContext(Dispatchers.Main) { result.success(success) }
          } catch (e: Exception) {
            withContext(Dispatchers.Main) {
              android.util.Log.e("MediagetterPlugin", "Failed to delete file: ${e.message}", e)
              result.error("ERROR", "Failed to delete file: ${e.message}", null)
            }
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun getAllImagesFromDevice(
      fromDate: Long? = null,
      limit: Int? = null,
      orderByDesc: Boolean = true
  ): List<Map<String, Any?>> {
    val images = mutableListOf<Map<String, Any?>>()
    val contentResolver: ContentResolver = context.contentResolver

    try {
      val uri: Uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

      val projection = arrayOf(
        MediaStore.Images.Media._ID,
        MediaStore.Images.Media.DISPLAY_NAME,
        MediaStore.Images.Media.DATA,
        MediaStore.Images.Media.SIZE,
        MediaStore.Images.Media.DATE_ADDED,
        MediaStore.Images.Media.DATE_MODIFIED,
        MediaStore.Images.Media.WIDTH,
        MediaStore.Images.Media.HEIGHT,
        MediaStore.Images.Media.MIME_TYPE
      )

      // Build selection clause for fromDate
      var selection: String? = null
      var selectionArgs: Array<String>? = null

      if (fromDate != null) {
        // Convert milliseconds to seconds for MediaStore
        val fromDateSeconds = fromDate / 1000
        selection = "${MediaStore.Images.Media.DATE_ADDED} >= ?"
        selectionArgs = arrayOf(fromDateSeconds.toString())
      }

      // Build sort order
      val sortOrder = if (orderByDesc) {
        "${MediaStore.Images.Media.DATE_ADDED} DESC"
      } else {
        "${MediaStore.Images.Media.DATE_ADDED} ASC"
      }

      val cursor: Cursor? = contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)

      cursor?.use {
        val idColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
        val nameColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
        val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.SIZE)
        val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_ADDED)
        val dateModifiedColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)
        val mimeTypeColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
        val dataColumn = try { it.getColumnIndexOrThrow(MediaStore.Images.Media.DATA) } catch (e: IllegalArgumentException) { -1 }
        val widthColumn = try { it.getColumnIndexOrThrow(MediaStore.Images.Media.WIDTH) } catch (e: IllegalArgumentException) { -1 }
        val heightColumn = try { it.getColumnIndexOrThrow(MediaStore.Images.Media.HEIGHT) } catch (e: IllegalArgumentException) { -1 }

        var count = 0
        while (it.moveToNext()) {
          if (limit != null && count >= limit) break

          try {
            val id = it.getLong(idColumn)
            val name = it.getString(nameColumn) ?: "Unknown"
            val path = if (dataColumn != -1) it.getString(dataColumn) else null
            val size = it.getLong(sizeColumn)
            val dateAdded = it.getLong(dateAddedColumn)
            val dateModified = it.getLong(dateModifiedColumn)
            val width = if (widthColumn != -1) it.getInt(widthColumn) else 0
            val height = if (heightColumn != -1) it.getInt(heightColumn) else 0
            val mimeType = it.getString(mimeTypeColumn) ?: "image/*"
            val fileExtension = name.substringAfterLast(".", "").lowercase()

            val contentUri = Uri.withAppendedPath(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id.toString())

            val imageMap = mapOf(
              "id" to id,
              "name" to name,
              "path" to path,
              "uri" to contentUri.toString(),
              "size" to size,
              "dateAdded" to dateAdded * 1000,
              "dateModified" to dateModified * 1000,
              "width" to width,
              "height" to height,
              "mimeType" to mimeType,
              "fileExtension" to if (fileExtension.isNotEmpty()) fileExtension else null
            )

            images.add(imageMap)
            count++
          } catch (e: Exception) {
            android.util.Log.w("MediagetterPlugin", "Skipping image: ${e.message}")
            continue
          }
        }
      } ?: throw Exception("Unable to query MediaStore - cursor is null")
    } catch (e: SecurityException) {
      android.util.Log.e("MediagetterPlugin", "Permission denied", e)
      throw Exception("Permission denied. Ensure READ_EXTERNAL_STORAGE or READ_MEDIA_IMAGES permissions are granted.")
    } catch (e: Exception) {
      android.util.Log.e("MediagetterPlugin", "Error accessing MediaStore", e)
      throw Exception("Error accessing MediaStore: ${e.message}")
    }

    return images
  }

  private fun getAllVideosFromDevice(
      fromDate: Long? = null,
      limit: Int? = null,
      orderByDesc: Boolean = true
  ): List<Map<String, Any?>> {
    val videos = mutableListOf<Map<String, Any?>>()
    val contentResolver: ContentResolver = context.contentResolver

    try {
      val uri: Uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI

      val projection = arrayOf(
        MediaStore.Video.Media._ID,
        MediaStore.Video.Media.DISPLAY_NAME,
        MediaStore.Video.Media.DATA,
        MediaStore.Video.Media.SIZE,
        MediaStore.Video.Media.DATE_ADDED,
        MediaStore.Video.Media.DATE_MODIFIED,
        MediaStore.Video.Media.WIDTH,
        MediaStore.Video.Media.HEIGHT,
        MediaStore.Video.Media.DURATION,
        MediaStore.Video.Media.MIME_TYPE
      )

      // Build selection clause for fromDate
      var selection: String? = null
      var selectionArgs: Array<String>? = null

      if (fromDate != null) {
        val fromDateSeconds = fromDate / 1000
        selection = "${MediaStore.Video.Media.DATE_ADDED} >= ?"
        selectionArgs = arrayOf(fromDateSeconds.toString())
      }

      // Build sort order
      val sortOrder = if (orderByDesc) {
        "${MediaStore.Video.Media.DATE_ADDED} DESC"
      } else {
        "${MediaStore.Video.Media.DATE_ADDED} ASC"
      }

      val cursor: Cursor? = contentResolver.query(uri, projection, selection, selectionArgs, sortOrder)

      cursor?.use {
        val idColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media._ID)
        val nameColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DISPLAY_NAME)
        val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.SIZE)
        val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_ADDED)
        val dateModifiedColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DATE_MODIFIED)
        val durationColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.DURATION)
        val mimeTypeColumn = it.getColumnIndexOrThrow(MediaStore.Video.Media.MIME_TYPE)
        val dataColumn = try { it.getColumnIndexOrThrow(MediaStore.Video.Media.DATA) } catch (e: IllegalArgumentException) { -1 }
        val widthColumn = try { it.getColumnIndexOrThrow(MediaStore.Video.Media.WIDTH) } catch (e: IllegalArgumentException) { -1 }
        val heightColumn = try { it.getColumnIndexOrThrow(MediaStore.Video.Media.HEIGHT) } catch (e: IllegalArgumentException) { -1 }

        var count = 0
        while (it.moveToNext()) {
          if (limit != null && count >= limit) break

          try {
            val id = it.getLong(idColumn)
            val name = it.getString(nameColumn) ?: "Unknown"
            val path = if (dataColumn != -1) it.getString(dataColumn) else null
            val size = it.getLong(sizeColumn)
            val dateAdded = it.getLong(dateAddedColumn)
            val dateModified = it.getLong(dateModifiedColumn)
            val duration = it.getLong(durationColumn)
            val width = if (widthColumn != -1) it.getInt(widthColumn) else 0
            val height = if (heightColumn != -1) it.getInt(heightColumn) else 0
            val mimeType = it.getString(mimeTypeColumn) ?: "video/*"
            val fileExtension = name.substringAfterLast(".", "").lowercase()

            val contentUri = Uri.withAppendedPath(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, id.toString())

            val videoMap = mapOf(
              "id" to id,
              "name" to name,
              "path" to path,
              "uri" to contentUri.toString(),
              "size" to size,
              "dateAdded" to dateAdded * 1000,
              "dateModified" to dateModified * 1000,
              "duration" to duration,
              "width" to width,
              "height" to height,
              "mimeType" to mimeType,
              "fileExtension" to if (fileExtension.isNotEmpty()) fileExtension else null
            )

            videos.add(videoMap)
            count++
          } catch (e: Exception) {
            android.util.Log.w("MediagetterPlugin", "Skipping video: ${e.message}")
            continue
          }
        }
      } ?: throw Exception("Unable to query MediaStore - cursor is null")
    } catch (e: SecurityException) {
      android.util.Log.e("MediagetterPlugin", "Permission denied", e)
      throw Exception("Permission denied. Ensure READ_EXTERNAL_STORAGE or READ_MEDIA_VIDEO permissions are granted.")
    } catch (e: Exception) {
      android.util.Log.e("MediagetterPlugin", "Error accessing MediaStore", e)
      throw Exception("Error accessing MediaStore: ${e.message}")
    }

    return videos
  }

  private fun getAllFilesFromDevice(
      fromDate: Long? = null,
      limit: Int? = null,
      orderByDesc: Boolean = true,
      fileExtensions: List<String>? = null
  ): List<Map<String, Any?>> {
    val files = mutableListOf<Map<String, Any?>>()
    val contentResolver: ContentResolver = context.contentResolver

    try {
      val uri: Uri = MediaStore.Files.getContentUri("external")

      val projection = arrayOf(
        MediaStore.Files.FileColumns._ID,
        MediaStore.Files.FileColumns.DISPLAY_NAME,
        MediaStore.Files.FileColumns.DATA,
        MediaStore.Files.FileColumns.SIZE,
        MediaStore.Files.FileColumns.DATE_ADDED,
        MediaStore.Files.FileColumns.DATE_MODIFIED,
        MediaStore.Files.FileColumns.MIME_TYPE,
        MediaStore.Files.FileColumns.MEDIA_TYPE
      )

      // Build selection clause
      var selection: String? = null
      val selectionArgsList = mutableListOf<String>()

      if (fromDate != null) {
        val fromDateSeconds = fromDate / 1000
        selection = "${MediaStore.Files.FileColumns.DATE_ADDED} >= ?"
        selectionArgsList.add(fromDateSeconds.toString())
      }

      if (fileExtensions != null && fileExtensions.isNotEmpty()) {
        val extensionConditions = fileExtensions.map {
          "${MediaStore.Files.FileColumns.DATA} LIKE ?"
        }.joinToString(" OR ")

        if (selection.isNullOrEmpty()) {
          selection = "($extensionConditions)"
        } else {
          selection += " AND ($extensionConditions)"
        }

        fileExtensions.forEach { ext ->
          selectionArgsList.add("%.$ext")
        }
      }

      val selectionArgs = if (selectionArgsList.isNotEmpty()) selectionArgsList.toTypedArray() else null

      // Build sort order
      val sortOrder = if (orderByDesc) {
        "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"
      } else {
        "${MediaStore.Files.FileColumns.DATE_ADDED} ASC"
      }

      val cursor: Cursor? = contentResolver.query(
        uri,
        projection,
        selection,
        selectionArgs,
        sortOrder
      )

      cursor?.use {
        val idColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
        val nameColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
        val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)
        val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)
        val dateModifiedColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_MODIFIED)
        val mimeTypeColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MIME_TYPE)
        val mediaTypeColumn = it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE)
        val dataColumn = try { it.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA) } catch (e: IllegalArgumentException) { -1 }

        var count = 0
        while (it.moveToNext()) {
          if (limit != null && count >= limit) break

          try {
            val id = it.getLong(idColumn)
            val name = it.getString(nameColumn) ?: "Unknown"
            val path = if (dataColumn != -1) it.getString(dataColumn) else null
            val size = it.getLong(sizeColumn)
            val dateAdded = it.getLong(dateAddedColumn)
            val dateModified = it.getLong(dateModifiedColumn)
            val mimeType = it.getString(mimeTypeColumn) ?: "application/octet-stream"
            val mediaType = it.getInt(mediaTypeColumn)
            val fileExtension = name.substringAfterLast(".", "").lowercase()

            val contentUri = Uri.withAppendedPath(
              MediaStore.Files.getContentUri("external"),
              id.toString()
            )

            val fileMap = mapOf(
              "id" to id,
              "name" to name,
              "path" to path,
              "uri" to contentUri.toString(),
              "size" to size,
              "dateAdded" to dateAdded * 1000,
              "dateModified" to dateModified * 1000,
              "mimeType" to mimeType,
              "fileExtension" to if (fileExtension.isNotEmpty()) fileExtension else null,
              "mediaType" to mediaType
            )

            files.add(fileMap)
            count++
          } catch (e: Exception) {
            android.util.Log.w("MediagetterPlugin", "Skipping file: ${e.message}")
            continue
          }
        }
      } ?: throw Exception("Unable to query MediaStore - cursor is null")
    } catch (e: SecurityException) {
      android.util.Log.e("MediagetterPlugin", "Permission denied", e)
      throw Exception("Permission denied. Ensure READ_EXTERNAL_STORAGE or READ_MEDIA_* permissions are granted.")
    } catch (e: Exception) {
      android.util.Log.e("MediagetterPlugin", "Error accessing MediaStore", e)
      throw Exception("Error accessing MediaStore: ${e.message}")
    }

    return files
  }

  private fun getDownloadFolderItems(
      fromDate: Long? = null,
      limit: Int? = null,
      orderByDesc: Boolean = true
  ): List<Map<String, Any?>> {
    val files = mutableListOf<Map<String, Any?>>()
    val contentResolver: ContentResolver = context.contentResolver

    try {
      // Use MediaStore.Downloads for Android 10+ compatibility
      val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        MediaStore.Downloads.EXTERNAL_CONTENT_URI
      } else {
        MediaStore.Files.getContentUri("external")
      }

      val projection = arrayOf(
        MediaStore.Downloads._ID,
        MediaStore.Downloads.DISPLAY_NAME,
        MediaStore.Downloads.DATA,
        MediaStore.Downloads.SIZE,
        MediaStore.Downloads.DATE_ADDED,
        MediaStore.Downloads.DATE_MODIFIED,
        MediaStore.Downloads.MIME_TYPE
      )

      // Build selection clause
      var selection: String? = null
      val selectionArgsList = mutableListOf<String>()

      if (fromDate != null) {
        val fromDateSeconds = fromDate / 1000
        selection = "${MediaStore.Downloads.DATE_ADDED} >= ?"
        selectionArgsList.add(fromDateSeconds.toString())
      }

      // For pre-Android 10, filter by Download folder path
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
        val downloadPath = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).absolutePath
        val pathSelection = "${MediaStore.Files.FileColumns.DATA} LIKE ?"
        selection = if (selection.isNullOrEmpty()) pathSelection else "$selection AND $pathSelection"
        selectionArgsList.add("$downloadPath%")
      }

      val selectionArgs = if (selectionArgsList.isNotEmpty()) selectionArgsList.toTypedArray() else null

      // Build sort order
      val sortOrder = if (orderByDesc) {
        "${MediaStore.Downloads.DATE_ADDED} DESC"
      } else {
        "${MediaStore.Downloads.DATE_ADDED} ASC"
      }

      val cursor: Cursor? = contentResolver.query(
        uri, projection, selection, selectionArgs, sortOrder
      )

      cursor?.use {
        val idColumn = it.getColumnIndexOrThrow(MediaStore.Downloads._ID)
        val nameColumn = it.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
        val sizeColumn = it.getColumnIndexOrThrow(MediaStore.Downloads.SIZE)
        val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Downloads.DATE_ADDED)
        val dateModifiedColumn = it.getColumnIndexOrThrow(MediaStore.Downloads.DATE_MODIFIED)
        val mimeTypeColumn = it.getColumnIndexOrThrow(MediaStore.Downloads.MIME_TYPE)
        val dataColumn = try { it.getColumnIndexOrThrow(MediaStore.Downloads.DATA) } catch (e: IllegalArgumentException) { -1 }

        var count = 0
        while (it.moveToNext()) {
          if (limit != null && count >= limit) break

          try {
            val id = it.getLong(idColumn)
            val name = it.getString(nameColumn) ?: "Unknown"
            val path = if (dataColumn != -1) it.getString(dataColumn) else null
            val size = it.getLong(sizeColumn)
            val dateAdded = it.getLong(dateAddedColumn)
            val dateModified = it.getLong(dateModifiedColumn)
            val mimeType = it.getString(mimeTypeColumn) ?: "application/octet-stream"
            val fileExtension = name.substringAfterLast(".", "").lowercase()

            val contentUri = Uri.withAppendedPath(
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Downloads.EXTERNAL_CONTENT_URI
              } else {
                MediaStore.Files.getContentUri("external")
              }, id.toString()
            )

            val fileMap = mapOf(
              "id" to id,
              "name" to name,
              "path" to path,
              "uri" to contentUri.toString(),
              "size" to size,
              "dateAdded" to dateAdded * 1000,
              "dateModified" to dateModified * 1000,
              "mimeType" to mimeType,
              "fileExtension" to if (fileExtension.isNotEmpty()) fileExtension else null
            )

            files.add(fileMap)
            count++
          } catch (e: Exception) {
            android.util.Log.w("MediagetterPlugin", "Skipping file: ${e.message}")
            continue
          }
        }
      } ?: throw Exception("Unable to query MediaStore - cursor is null")

      // Fallback for non-indexed files in Download folder (if MANAGE_EXTERNAL_STORAGE is granted)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && Environment.isExternalStorageManager()) {
        val downloadDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        if (downloadDir.exists() && downloadDir.isDirectory) {
          downloadDir.listFiles()?.forEach { file ->
            if (file.isFile && (fromDate == null || file.lastModified() >= fromDate)) {
              val name = file.name
              val fileExtension = name.substringAfterLast(".", "").lowercase()
              val mimeType = when (fileExtension) {
                "pdf" -> "application/pdf"
                "txt" -> "text/plain"
                "zip" -> "application/zip"
                "doc" -> "application/msword"
                "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                "jpg" -> "image/jpeg"
                "png" -> "image/png"
                "mp4" -> "video/mp4"
                "mp3" -> "audio/mpeg"
                "wav" -> "audio/wav"
                else -> "application/octet-stream"
              }

              val fileMap = mapOf(
                "id" to file.hashCode().toLong(),
                "name" to name,
                "path" to file.absolutePath,
                "uri" to "file://${file.absolutePath}",
                "size" to file.length(),
                "dateAdded" to file.lastModified(),
                "dateModified" to file.lastModified(),
                "mimeType" to mimeType,
                "fileExtension" to if (fileExtension.isNotEmpty()) fileExtension else null
              )

              if (!files.any { it["path"] == fileMap["path"] }) {
                files.add(fileMap)
              }
            }
          }
        }
      }
    } catch (e: SecurityException) {
      android.util.Log.e("MediagetterPlugin", "Permission denied", e)
      throw Exception("Permission denied. Ensure READ_EXTERNAL_STORAGE or READ_MEDIA_* permissions are granted.")
    } catch (e: Exception) {
      android.util.Log.e("MediagetterPlugin", "Error accessing Download folder", e)
      throw Exception("Error accessing Download folder: ${e.message}")
    }

    return files
  }





  /// Deletes a file by its path or URI.
  private fun deleteFile(path: String): Boolean {
    try {
      val file = File(path)
      if (file.exists()) {
        // Direct file deletion for app-owned or accessible files
        return file.delete()
      } else {
        // Try deleting via MediaStore using content URI
        val uri = Uri.parse(path)
        val contentResolver: ContentResolver = context.contentResolver
        val deletedRows = contentResolver.delete(uri, null, null)
        return deletedRows > 0
      }
    } catch (e: SecurityException) {
      android.util.Log.e("MediagetterPlugin", "Permission denied for deletion", e)
      return false
    } catch (e: Exception) {
      android.util.Log.e("MediagetterPlugin", "Error deleting file: ${e.message}", e)
      return false
    }
  }

  /// Determines MIME type based on file extension.
  private fun getMimeType(path: String): String {
    val extension = path.substringAfterLast(".", "").lowercase()
    return when (extension) {
      "pdf" -> "application/pdf"
      "txt" -> "text/plain"
      "zip" -> "application/zip"
      "doc" -> "application/msword"
      "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "jpg" -> "image/jpeg"
      "png" -> "image/png"
      "mp4" -> "video/mp4"
      "mp3" -> "audio/mpeg"
      "wav" -> "audio/wav"
      else -> "*/*"
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}