import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../models/compression_result.dart';
import '../models/compression_settings.dart';
import '../utils/file_utils.dart';
import 'file_service.dart';

class CompressionService {
  final FileService _fileService;

  final _progressController = StreamController<double>.broadcast();
  FFmpegSession? _activeSession;

  /// A broadcast stream emitting progress values between 0.0 and 1.0.
  Stream<double> get progressStream => _progressController.stream;

  CompressionService(this._fileService);

  /// Builds the FFmpeg argument string from [settings].
  String buildCommand({
    required String inputPath,
    required String outputPath,
    required CompressionSettings settings,
  }) {
    final args = <String>[
      '-i',
      inputPath,
      '-y', // overwrite output
    ];

    // Scale filter (skip for original resolution)
    if (settings.resolution != VideoResolution.original) {
      args.addAll([
        '-vf',
        'scale=${settings.resolution.width}:${settings.resolution.height}'
            ':force_original_aspect_ratio=decrease,'
            'pad=${settings.resolution.width}:${settings.resolution.height}'
            ':(ow-iw)/2:(oh-ih)/2',
      ]);
    }

    // Video codec and quality
    args.addAll([
      '-c:v', settings.videoCodec,
      '-crf', settings.quality.crf.toString(),
      '-preset', settings.preset.value,
    ]);

    // Audio codec and bitrate
    args.addAll([
      '-c:a', settings.audioCodec,
      '-b:a', '${settings.audioBitrate}k',
    ]);

    args.add(outputPath);
    return args.join(' ');
  }

  /// Compresses the video at [inputPath] using the given [settings].
  ///
  /// Progress updates are emitted via [progressStream].
  /// After successful compression the original file is deleted if
  /// [settings.deleteOriginal] is true.
  Future<CompressionResult> compress({
    required String inputPath,
    required String outputDir,
    required CompressionSettings settings,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 1. Gather input info
    final inputFile = File(inputPath);
    final originalSize = await inputFile.length();
    final videoInfo = await _fileService.getVideoInfo(inputPath);
    final totalDurationMs = videoInfo.duration?.inMilliseconds ?? 0;

    // 2. Prepare output path in user-chosen directory
    final outputPath = FileUtils.generateOutputPath(inputPath, outputDir);

    // 3. Build command
    final command = buildCommand(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: settings,
    );

    // 4. Execute asynchronously
    final completer = Completer<CompressionResult>();

    _activeSession = await FFmpegKit.executeAsync(
      command,
      // ── completion callback ──
      (FFmpegSession session) async {
        final returnCode = await session.getReturnCode();
        stopwatch.stop();

        if (ReturnCode.isSuccess(returnCode)) {
          final compressedSize = await File(outputPath).length();

          bool deleted = false;
          if (settings.deleteOriginal) {
            deleted = await _fileService.deleteFile(inputPath);
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
          // Clean up partial output
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
      // ── log callback ──
      null,
      // ── statistics callback (progress) ──
      (statistics) {
        if (totalDurationMs > 0) {
          final progress = statistics.getTime() / totalDurationMs;
          _progressController.add(progress.clamp(0.0, 1.0));
        }
      },
    );

    return completer.future;
  }

  /// Cancels the currently running compression session.
  Future<void> cancel() async {
    if (_activeSession != null) {
      await FFmpegKit.cancel(_activeSession!.getSessionId());
    }
  }

  void dispose() {
    _progressController.close();
  }
}
