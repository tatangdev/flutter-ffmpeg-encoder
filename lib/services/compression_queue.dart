import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../models/compression_job.dart';
import '../models/compression_result.dart';
import '../utils/file_utils.dart';
import 'compression_service.dart';
import 'database_service.dart';
import 'notification_service.dart';

class CompressionQueue extends ChangeNotifier {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;
  final List<CompressionJob> _jobs = [];
  Timer? _progressTimer;
  double _lastReportedProgress = 0.0;

  List<CompressionJob> get jobs => List.unmodifiable(_jobs);

  CompressionQueue(this._databaseService, this._notificationService);

  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'compression_foreground',
        channelName: 'Video Compression',
        channelDescription: 'Keeps compression running in background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    await _databaseService.markInterruptedJobsAsFailed();
    final rows = await _databaseService.getAllJobs();
    _jobs.addAll(rows.map((row) => CompressionJob.fromMap(row)));
    notifyListeners();
  }

  Future<void> _startForegroundService(String fileName) async {
    await FlutterForegroundTask.startService(
      notificationTitle: 'Compressing: $fileName',
      notificationText: 'Encoding in progress...',
    );
  }

  Future<void> _stopForegroundServiceIfIdle() async {
    final hasActive = _jobs.any(
      (j) => j.status == JobStatus.compressing || j.status == JobStatus.pending,
    );
    if (!hasActive) {
      await FlutterForegroundTask.stopService();
    }
  }

  bool _isProcessing = false;

  Future<void> addJob(CompressionJob job) async {
    _jobs.insert(0, job);
    await _databaseService.insertJob(job.toMap());
    notifyListeners();
    _processNext();
  }

  Future<void> _processNext() async {
    if (_isProcessing) return;

    final idx = _jobs.indexWhere((j) => j.status == JobStatus.pending);
    if (idx == -1) return;

    _isProcessing = true;
    await _startJob(_jobs[idx]);
    _isProcessing = false;
    _processNext();
  }

  Future<void> _startJob(CompressionJob job) async {
    job.status = JobStatus.compressing;
    _lastReportedProgress = 0.0;
    await _databaseService.updateJob(job.toMap());
    notifyListeners();
    await _startForegroundService(job.fileName);

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

      // Throttle UI updates — only when progress changes by >= 1%
      _progressTimer?.cancel();
      _progressTimer = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) {
          if ((job.progress - _lastReportedProgress).abs() >= 0.01) {
            _lastReportedProgress = job.progress;
            notifyListeners();
            _notificationService.showProgress(
              jobId: job.id,
              fileName: job.fileName,
              progress: job.progress,
            );
          }
        },
      );

      final result = await completer.future;
      _progressTimer?.cancel();
      _progressTimer = null;

      // If cancelJob() already marked this cancelled, just clean up the
      // notification — don't overwrite the status or show a failure toast.
      if (job.status == JobStatus.cancelled) {
        await _notificationService.cancel(job.id);
      } else {
        job.result = result;
        job.status = result.success ? JobStatus.completed : JobStatus.failed;

        if (result.success) {
          _notificationService.showCompleted(
            jobId: job.id,
            fileName: job.fileName,
            savedPercentage: result.savedPercentage.toStringAsFixed(1),
          );
        } else {
          _notificationService.showFailed(
            jobId: job.id,
            fileName: job.fileName,
            errorMessage: result.errorMessage,
          );
        }
      }
    } catch (e) {
      if (job.status != JobStatus.cancelled) {
        job.result = CompressionResult(
          success: false,
          errorMessage: e.toString(),
        );
        job.status = JobStatus.failed;
        _notificationService.showFailed(
          jobId: job.id,
          fileName: job.fileName,
          errorMessage: e.toString(),
        );
      }
    }

    job.session = null;
    await _databaseService.updateJob(job.toMap());
    notifyListeners();
    await _stopForegroundServiceIfIdle();
  }

  Future<void> cancelJob(String jobId) async {
    final job = _jobs.firstWhere((j) => j.id == jobId);
    if (job.session != null) {
      // Mark cancelled and update UI immediately.
      job.status = JobStatus.cancelled;
      notifyListeners();
      // Signal FFmpeg to stop. The _startJob completer will resolve via the
      // FFmpegKit callback, and _startJob's normal cleanup path (DB update,
      // foreground service check, _processNext) runs without a race.
      await FFmpegKit.cancel(job.session!.getSessionId());
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
        _notificationService.cancel(job.id);
      }
    }
    FlutterForegroundTask.stopService();
    _databaseService.close();
    super.dispose();
  }
}
