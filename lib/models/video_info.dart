import '../utils/file_utils.dart';

class VideoInfo {
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final Duration? duration;
  final int? width;
  final int? height;
  final String? videoCodec;
  final double? bitrate;
  final String? format;

  const VideoInfo({
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    this.duration,
    this.width,
    this.height,
    this.videoCodec,
    this.bitrate,
    this.format,
  });

  String get formattedSize => FileUtils.formatFileSize(sizeBytes);

  String get resolution =>
      (width != null && height != null) ? '${width}x$height' : 'Unknown';
}
