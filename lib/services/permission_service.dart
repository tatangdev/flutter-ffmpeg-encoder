import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests the appropriate storage permissions based on Android version.
  /// Returns true if all required permissions are granted.
  ///
  /// On Android 13+ the plugin maps [Permission.videos] to READ_MEDIA_VIDEO.
  /// On older versions it falls back to [Permission.storage].
  /// Also requests [Permission.manageExternalStorage] on Android 11+ so we
  /// can write compressed files to shared directories like Movies/.
  Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    // Request read access to videos
    var status = await Permission.videos.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
      if (!status.isGranted) return false;
    }

    // Request broad storage access so we can write to Movies/
    final manageStatus = await Permission.manageExternalStorage.request();
    if (!manageStatus.isGranted) {
      // Still usable — will fall back to app-specific external storage
    }

    return true;
  }

  /// Checks whether storage permissions are already granted.
  Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    final videosGranted = await Permission.videos.isGranted;
    final storageGranted = await Permission.storage.isGranted;
    return videosGranted || storageGranted;
  }
}
