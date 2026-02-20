import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/video_info.dart';
import '../utils/constants.dart';

class FileService {
  /// Opens the system file picker to select a video file.
  /// Returns null if the user cancels.
  Future<File?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) return null;
    return File(path);
  }

  /// Retrieves video metadata using FFprobe.
  Future<VideoInfo> getVideoInfo(String filePath) async {
    final file = File(filePath);
    final sizeBytes = await file.length();
    final fileName = p.basename(filePath);

    int? width;
    int? height;
    Duration? duration;
    String? videoCodec;
    double? bitrate;
    String? format;

    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();

      if (info != null) {
        final durationStr = info.getDuration();
        if (durationStr != null) {
          final seconds = double.tryParse(durationStr);
          if (seconds != null) {
            duration = Duration(milliseconds: (seconds * 1000).round());
          }
        }

        final bitrateStr = info.getBitrate();
        if (bitrateStr != null) {
          bitrate = double.tryParse(bitrateStr);
        }

        format = info.getFormat();

        final streams = info.getStreams();
        for (final stream in streams) {
          final properties = stream.getAllProperties();
          if (properties == null) continue;

          final codecType = properties['codec_type'] as String?;
          if (codecType == 'video') {
            width = properties['width'] as int?;
            height = properties['height'] as int?;
            videoCodec = properties['codec_name'] as String?;
            break;
          }
        }
      }
    } catch (_) {
      // Return partial info if FFprobe fails
    }

    return VideoInfo(
      filePath: filePath,
      fileName: fileName,
      sizeBytes: sizeBytes,
      duration: duration,
      width: width,
      height: height,
      videoCodec: videoCodec,
      bitrate: bitrate,
      format: format,
    );
  }

  /// Extracts a single frame from the video as a JPEG thumbnail.
  /// Returns the thumbnail [File], or null if extraction fails.
  Future<File?> extractThumbnail(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = p.join(
      tempDir.path,
      'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    String quote(String p) => "'${p.replaceAll("'", r"'\''")}'";
    final session = await FFmpegKit.execute(
      '-i ${quote(videoPath)} -ss 00:00:01 -vframes 1 -q:v 2 -y ${quote(thumbPath)}',
    );
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      final file = File(thumbPath);
      if (await file.exists()) return file;
    }
    return null;
  }

  /// Deletes the file at [filePath].
  /// Returns true if deletion succeeded, false otherwise.
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } on FileSystemException {
      return false;
    }
  }

  /// Returns a user-accessible output directory for compressed videos.
  ///
  /// Saves to `/storage/emulated/0/Movies/VideoCompressor/` which is
  /// visible in file managers and the gallery.
  /// Falls back to app-specific external storage if that fails.
  Future<String> getOutputDirectory() async {
    // Try the shared Movies directory first
    const moviesPath = '/storage/emulated/0/Movies/VideoCompressor';
    final moviesDir = Directory(moviesPath);
    try {
      if (!await moviesDir.exists()) {
        await moviesDir.create(recursive: true);
      }
      // Verify we can write to it
      final testFile = File(p.join(moviesPath, '.test'));
      await testFile.writeAsString('');
      await testFile.delete();
      return moviesPath;
    } catch (_) {
      // Fall back to app-specific external storage
    }

    // Fallback: app external storage (still visible in file managers)
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      final outputDir =
          Directory(p.join(extDir.path, AppConstants.outputDirectory));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      return outputDir.path;
    }

    // Last resort: app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir =
        Directory(p.join(appDir.path, AppConstants.outputDirectory));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir.path;
  }
}
