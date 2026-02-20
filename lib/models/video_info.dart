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

  Map<String, dynamic> toMap() {
    return {
      'video_path': filePath,
      'file_name': fileName,
      'size_bytes': sizeBytes,
      'duration_ms': duration?.inMilliseconds,
      'width': width,
      'height': height,
      'video_codec': videoCodec,
      'bitrate': bitrate,
      'format': format,
    };
  }

  factory VideoInfo.fromMap(Map<String, dynamic> map) {
    return VideoInfo(
      filePath: map['video_path'] as String,
      fileName: map['file_name'] as String,
      sizeBytes: map['size_bytes'] as int,
      duration: map['duration_ms'] != null
          ? Duration(milliseconds: map['duration_ms'] as int)
          : null,
      width: map['width'] as int?,
      height: map['height'] as int?,
      videoCodec: map['video_codec'] as String?,
      bitrate: (map['bitrate'] as num?)?.toDouble(),
      format: map['format'] as String?,
    );
  }
}
