import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';

import 'compression_result.dart';
import 'compression_settings.dart';

enum JobStatus { pending, compressing, completed, failed, cancelled }

class CompressionJob {
  final String id;
  final String inputPath;
  final String outputDir;
  final String fileName;
  final CompressionSettings settings;
  final DateTime createdAt;
  final File? thumbnailFile;

  JobStatus status;
  double progress;
  CompressionResult? result;
  FFmpegSession? session;

  CompressionJob({
    required this.id,
    required this.inputPath,
    required this.outputDir,
    required this.fileName,
    required this.settings,
    this.thumbnailFile,
    this.status = JobStatus.pending,
    this.progress = 0.0,
    this.result,
    this.session,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
