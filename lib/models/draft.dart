import 'dart:io';

import 'compression_settings.dart';
import 'video_info.dart';

class Draft {
  final VideoInfo videoInfo;
  final String? thumbnailPath;
  final String? outputDir;
  final CompressionSettings settings;

  const Draft({
    required this.videoInfo,
    this.thumbnailPath,
    this.outputDir,
    this.settings = const CompressionSettings(),
  });

  File? get thumbnailFile =>
      thumbnailPath != null ? File(thumbnailPath!) : null;

  Map<String, dynamic> toMap() {
    return {
      'id': 'current',
      ...videoInfo.toMap(),
      'thumbnail_path': thumbnailPath,
      'output_dir': outputDir,
      ...settings.toMap(),
    };
  }

  factory Draft.fromMap(Map<String, dynamic> map) {
    return Draft(
      videoInfo: VideoInfo.fromMap(map),
      thumbnailPath: map['thumbnail_path'] as String?,
      outputDir: map['output_dir'] as String?,
      settings: CompressionSettings.fromMap(map),
    );
  }
}
