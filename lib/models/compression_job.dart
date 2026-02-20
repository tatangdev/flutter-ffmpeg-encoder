import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';

import 'compression_result.dart';
import 'compression_settings.dart';
import '../utils/file_utils.dart' show enumByName;

enum JobStatus { pending, compressing, completed, failed, cancelled }

class CompressionJob {
  final String id;
  final String inputPath;
  final String outputDir;
  final String fileName;
  final CompressionSettings settings;
  final DateTime createdAt;
  final File? thumbnailFile;
  final int? durationMs; // Used for progress tracking, avoids re-probing

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
    this.durationMs,
    this.status = JobStatus.pending,
    this.progress = 0.0,
    this.result,
    this.session,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'input_path': inputPath,
      'output_dir': outputDir,
      'file_name': fileName,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status.name,
      'progress': progress,
      'thumbnail_path': thumbnailFile?.path,
      ...settings.toMap(),
      if (result != null) ...result!.toMap(),
    };
  }

  factory CompressionJob.fromMap(Map<String, dynamic> map) {
    return CompressionJob(
      id: map['id'] as String,
      inputPath: map['input_path'] as String,
      outputDir: map['output_dir'] as String,
      fileName: map['file_name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      status: enumByName(JobStatus.values, map['status'] as String, JobStatus.failed),
      progress: (map['progress'] as num).toDouble(),
      thumbnailFile: map['thumbnail_path'] != null
          ? File(map['thumbnail_path'] as String)
          : null,
      settings: CompressionSettings.fromMap(map),
      result: map['result_success'] != null
          ? CompressionResult.fromMap(map)
          : null,
    );
  }
}
