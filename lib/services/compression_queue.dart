import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';

import '../models/compression_job.dart';
import '../models/compression_result.dart';
import '../utils/file_utils.dart';
import 'compression_service.dart';
import 'file_service.dart';

class CompressionQueue extends ChangeNotifier {
  final FileService _fileService;
  final List<CompressionJob> _jobs = [];

  List<CompressionJob> get jobs => List.unmodifiable(_jobs);

  CompressionQueue(this._fileService);

  Future<void> addJob(CompressionJob job) async {
    _jobs.insert(0, job);
    notifyListeners();
    _startJob(job);
  }

  Future<void> _startJob(CompressionJob job) async {
    job.status = JobStatus.compressing;
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      final inputFile = File(job.inputPath);
      final originalSize = await inputFile.length();
      final videoInfo = await _fileService.getVideoInfo(job.inputPath);
      final totalDurationMs = videoInfo.duration?.inMilliseconds ?? 0;

      final outputPath =
          FileUtils.generateOutputPath(job.inputPath, job.outputDir);

      final command = CompressionService.buildCommandStatic(
        inputPath: job.inputPath,
        outputPath: outputPath,
        settings: job.settings,
      );

      final completer = Completer<CompressionResult>();

      job.session = await FFmpegKit.executeAsync(
        command,
        (session) async {
          final returnCode = await session.getReturnCode();
          stopwatch.stop();

          if (ReturnCode.isSuccess(returnCode)) {
            final compressedSize = await File(outputPath).length();
            bool deleted = false;
            if (job.settings.deleteOriginal) {
              deleted = await _fileService.deleteFile(job.inputPath);
            }
            completer.complete(CompressionResult(
              success: true,
              outputPath: outputPath,
              originalSizeBytes: originalSize,
              compressedSizeBytes: compressedSize,
              compressionDuration: stopwatch.elapsed,
              ffmpegReturnCode: returnCode?.getValue(),
              originalDeleted: deleted,
            ));
          } else if (ReturnCode.isCancel(returnCode)) {
            final partial = File(outputPath);
            if (await partial.exists()) await partial.delete();
            completer.complete(CompressionResult(
              success: false,
              errorMessage: 'Compression was cancelled',
              ffmpegReturnCode: returnCode?.getValue(),
            ));
          } else {
            completer.complete(CompressionResult(
              success: false,
              errorMessage:
                  'FFmpeg failed with return code ${returnCode?.getValue()}',
              ffmpegReturnCode: returnCode?.getValue(),
            ));
          }
        },
        null,
        (statistics) {
          if (totalDurationMs > 0) {
            job.progress =
                (statistics.getTime() / totalDurationMs).clamp(0.0, 1.0);
            notifyListeners();
          }
        },
      );

      final result = await completer.future;
      job.result = result;
      job.status = result.success ? JobStatus.completed : JobStatus.failed;
    } catch (e) {
      job.result = CompressionResult(
        success: false,
        errorMessage: e.toString(),
      );
      job.status = JobStatus.failed;
    }

    job.session = null;
    notifyListeners();
  }

  Future<void> cancelJob(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    if (job.session != null) {
      await FFmpegKit.cancel(job.session!.getSessionId());
      job.status = JobStatus.cancelled;
      job.session = null;
      notifyListeners();
    }
  }

  void removeJob(String jobId) {
    _jobs.removeWhere((j) => j.id == jobId);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final job in _jobs) {
      if (job.session != null) {
        FFmpegKit.cancel(job.session!.getSessionId());
      }
    }
    super.dispose();
  }
}
