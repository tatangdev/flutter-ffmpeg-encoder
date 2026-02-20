import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';

import '../models/compression_job.dart';
import '../models/compression_result.dart';
import '../utils/file_utils.dart';
import 'compression_service.dart';
import 'database_service.dart';

class CompressionQueue extends ChangeNotifier {
  final DatabaseService _databaseService;
  final List<CompressionJob> _jobs = [];
  Timer? _progressTimer;

  List<CompressionJob> get jobs => List.unmodifiable(_jobs);

  CompressionQueue(this._databaseService);

  Future<void> init() async {
    await _databaseService.markInterruptedJobsAsFailed();
    final rows = await _databaseService.getAllJobs();
    _jobs.addAll(rows.map((row) => CompressionJob.fromMap(row)));
    notifyListeners();
  }

  Future<void> addJob(CompressionJob job) async {
    _jobs.insert(0, job);
    await _databaseService.insertJob(job.toMap());
    notifyListeners();
    _startJob(job);
  }

  Future<void> _startJob(CompressionJob job) async {
    job.status = JobStatus.compressing;
    await _databaseService.updateJob(job.toMap());
    notifyListeners();

    final stopwatch = Stopwatch()..start();

    try {
      final inputFile = File(job.inputPath);
      final originalSize = await inputFile.length();
      final totalDurationMs = job.durationMs ?? 0;

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
              try {
                final original = File(job.inputPath);
                if (await original.exists()) {
                  await original.delete();
                  deleted = true;
                }
              } on FileSystemException {
                // Deletion failed, continue without deleting
              }
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
          }
        },
      );

      // Throttle UI updates to ~4fps instead of every FFmpeg stats callback
      _progressTimer?.cancel();
      _progressTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => notifyListeners(),
      );

      final result = await completer.future;
      _progressTimer?.cancel();
      _progressTimer = null;
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
    await _databaseService.updateJob(job.toMap());
    notifyListeners();
  }

  Future<void> cancelJob(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    if (job.session != null) {
      await FFmpegKit.cancel(job.session!.getSessionId());
      job.status = JobStatus.cancelled;
      job.session = null;
      await _databaseService.updateJob(job.toMap());
      notifyListeners();
    }
  }

  Future<void> removeJob(String jobId) async {
    _jobs.removeWhere((j) => j.id == jobId);
    await _databaseService.deleteJob(jobId);
    notifyListeners();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    for (final job in _jobs) {
      if (job.session != null) {
        FFmpegKit.cancel(job.session!.getSessionId());
      }
    }
    _databaseService.close();
    super.dispose();
  }
}
