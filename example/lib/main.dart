import 'package:flutter/material.dart';
import 'package:mediagetter/mediagetter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // For Platform checks

void main() {
  runApp(const FileManagerDemoApp());
}

/// The main application widget that sets up the file manager demo with an indigo theme.
class FileManagerDemoApp extends StatelessWidget {
  const FileManagerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Manager Demo BY MediaGetter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo, // Indigo as primary color
          primary: Colors.indigo,
          secondary: Colors.indigoAccent,
        ),
        useMaterial3: true, // Enable Material 3 for modern design
        appBarTheme: const AppBarTheme(
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),
      home: const FileManagerHomePage(title: 'File Manager'),
    );
  }
}

/// The main page widget that provides a file manager interface with tabs, search, and sorting.
class FileManagerHomePage extends StatefulWidget {
  const FileManagerHomePage({super.key, required this.title});

  final String title;

  @override
  State<FileManagerHomePage> createState() => _FileManagerHomePageState();
}

class _FileManagerHomePageState extends State<FileManagerHomePage> {
  // Lists to store fetched files from mediagetter
  List<dynamic> images = [];
  List<dynamic> videos = [];
  List<dynamic> files = [];
  List<dynamic> downloadedFiles = [];

  // State variables for UI
  bool isLoading = false; // Controls loading indicator
  String? errorMessage; // Displays error messages
  String searchQuery = ''; // Stores search input
  int selectedTab = 0; // Tracks current tab (0: All Files, 1: Downloads, 2: Images, 3: Videos)
  String sortBy = 'date'; // Sorting criteria (name, date, size)
  bool sortAscending = false; // Sort direction
  final TextEditingController _searchController = TextEditingController(); // Search field controller

  /// Requests storage permissions required for file access.
  Future<bool> _requestPermissions() async {
    // Request permissions for Android
    final statuses = await [
      Permission.storage, // Android 12 and below
      Permission.photos, // Images (Android 13+)
      Permission.videos, // Videos (Android 13+)
      Permission.audio, // Audio (Android 13+)
      if (Platform.isAndroid) Permission.manageExternalStorage, // Non-media files (Android 11+)
    ].request();

    // Check if permissions are granted
    final hasStorageAccess = statuses[Permission.storage]?.isGranted ?? false;
    final hasMediaAccess = (statuses[Permission.photos]?.isGranted ?? true) &&
        (statuses[Permission.videos]?.isGranted ?? true) &&
        (statuses[Permission.audio]?.isGranted ?? true);
    final hasFullAccess = statuses[Permission.manageExternalStorage]?.isGranted ?? true;

    if (!hasStorageAccess && !hasMediaAccess && !hasFullAccess) {
      setState(() {
        errorMessage = 'Please grant storage permissions to access files.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please grant storage permissions')),
      );
      if (statuses[Permission.storage]?.isPermanentlyDenied ?? false ||
          statuses[Permission.manageExternalStorage]!.isPermanentlyDenied ?? false) {
        await openAppSettings(); // Prompt user to enable permissions in settings
      }
      return false;
    }
    return true;
  }

  /// Fetches files using the mediagetter plugin.
  Future<void> _fetchFiles() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      images = [];
      videos = [];
      files = [];
      downloadedFiles = [];
    });

    try {
      // Fetch images from the last 7 days
      images = await Mediagetter().getAllImages(
        orderByDesc: !sortAscending,
        fromDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      debugPrint('👉🏻 Images: ${images.map((e) => e.path).toList()}');

      // Fetch all videos
      videos = await Mediagetter().getAllVideos(
        orderByDesc: !sortAscending,
      );
      debugPrint('👉🏻 Videos: ${videos.map((e) => e.path).toList()}');

      // Fetch files with common extensions
      files = await Mediagetter().getAllFiles(
        fileExtensions: ['pdf', 'txt', 'doc', 'docx', 'mp4', 'mp3', 'jpg', 'png', 'wav'],
        orderByDesc: !sortAscending,
      );
      debugPrint('👉🏻 Files: ${files.map((e) => e.path).toList()}');

      // Fetch files from the Download folder
      downloadedFiles = await Mediagetter().getDownloadFolderItems(
        orderByDesc: !sortAscending,
      );
      debugPrint('👉🏻 Downloaded Files: ${downloadedFiles.map((e) => e.path).toList()}');

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${downloadedFiles.length} files in Downloads')),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching files: $e';
      });
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching files: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Opens a file using its path or URI with the device's default app.
  Future<void> _openFile(String filePath) async {
    
  }

  /// Deletes a file using its path or URI and refreshes the file list.
  Future<void> _deleteFile(String filePath) async {
    final success = await Mediagetter().deleteFile(filePath: filePath);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File deleted')),
      );
      await _fetchFiles(); // Refresh file list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete file')),
      );
    }
  }

  /// Returns an icon based on file extension for visual identification.
  Widget _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'png':
      case 'jpeg':
        return const Icon(Icons.image, color: Colors.indigo);
      case 'mp4':
      case 'mov':
      case 'avi':
        return const Icon(Icons.video_library, color: Colors.red);
      case 'mp3':
      case 'wav':
        return const Icon(Icons.music_note, color: Colors.green);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'txt':
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.grey);
      default:
        return const Icon(Icons.insert_drive_file, color: Colors.grey);
    }
  }

  /// Formats file size into KB or MB for display.
  String _formatFileSize(int? size) {
    if (size == null) return 'Unknown';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Filters and sorts files based on search query and sort criteria.
  List<dynamic> _filterAndSortFiles(List<dynamic> files) {
    var filteredFiles = files.where((file) {
      final name = file.name?.toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    if (sortBy == 'name') {
      filteredFiles.sort((a, b) => sortAscending
          ? (a.name ?? '').compareTo(b.name ?? '')
          : (b.name ?? '').compareTo(a.name ?? ''));
    } else if (sortBy == 'size') {
      filteredFiles.sort((a, b) => sortAscending
          ? (a.size ?? 0).compareTo(b.size ?? 0)
          : (b.size ?? 0).compareTo(a.size ?? 0));
    }
    // Date sorting is handled by mediagetter
    return filteredFiles;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.indigoAccent], // Gradient for app bar
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(widget.title),
        actions: [
          // Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (value == 'ascending') {
                  sortAscending = !sortAscending;
                } else {
                  sortBy = value;
                  sortAscending = false; // Default to descending for new sort
                }
                _fetchFiles(); // Refresh with new sort order
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'size', child: Text('Sort by Size')),
              PopupMenuItem(
                value: 'ascending',
                child: Text(sortAscending ? 'Sort Descending' : 'Sort Ascending'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with clear button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.indigo, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          // Tabs for file categories
          DefaultTabController(
            length: 4,
            initialIndex: selectedTab,
            child: Column(
              children: [
                const TabBar(
                  indicatorColor: Colors.indigo,
                  labelColor: Colors.indigo,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'All Files'),
                    Tab(text: 'Downloads'),
                    Tab(text: 'Images'),
                    Tab(text: 'Videos'),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height - 250, // Adjust for app bar, search, and tab bar
                  child: TabBarView(
                    children: [
                      _buildFileList(_filterAndSortFiles(files), 'No files found.'),
                      _buildFileList(_filterAndSortFiles(downloadedFiles), 'No files in Downloads.'),
                      _buildFileList(_filterAndSortFiles(images), 'No images found.'),
                      _buildFileList(_filterAndSortFiles(videos), 'No videos found.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Refresh files after checking permissions
          if (await _requestPermissions()) {
            await _fetchFiles();
          }
        },
        backgroundColor: Colors.indigo,
        elevation: 6,
        tooltip: 'Refresh Files',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  /// Builds a list view for files with card-based UI and file details.
  Widget _buildFileList(List<dynamic> files, String emptyMessage) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, color: Colors.grey, size: 64),
            const SizedBox(height: 8),
            Text(emptyMessage, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final name = file.name ?? 'Unknown';
        final path = file.path ?? file.uri ?? 'No path';
        final extension = file.fileExtension?.toLowerCase();
        final size = _formatFileSize(file.size);
        final date = file.dateModified;

        return Card(
          child: ListTile(
            leading: extension == 'jpg' || extension == 'png' || extension == 'jpeg'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      file.uri,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _getFileIcon(extension),
                    ),
                  )
                : _getFileIcon(extension),
            title: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Path: $path\nSize: $size\nModified: $date'),
            onTap: () => _openFile(path), // Open file on tap
            onLongPress: () {
              // Show file details and actions on long press
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('File Details'),
                  content: Text(
                    'Name: $name\nPath: $path\nSize: $size\nModified: $date\nType: ${extension ?? "Unknown"}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => _openFile(path), // Open file
                      child: const Text('Open'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _deleteFile(path); // Delete file
                        Navigator.pop(context); // Close dialog
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}