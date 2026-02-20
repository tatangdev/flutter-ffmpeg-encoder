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
  static String buildCommandStatic({
    required String inputPath,
    required String outputPath,
    required CompressionSettings settings,
  }) {
    final p = settings.resolvedPreset;
    final args = <String>[
      '-i', inputPath,
      '-y',
    ];

    // Video filter chain
    final outW = settings.resolvedWidth;
    final outH = settings.resolvedHeight;
    if (settings.aspectRatio.isOriginal) {
      // Keep original resolution, only force fps
      args.addAll(['-vf', 'fps=${p.fps}']);
    } else if (settings.fit == VideoFit.cover) {
      // Fill frame and crop overflow
      args.addAll([
        '-vf',
        'scale=$outW:$outH:force_original_aspect_ratio=increase,'
            'crop=$outW:$outH,'
            'setsar=1,'
            'fps=${p.fps}',
      ]);
    } else {
      // Fit entire video, pad with black bars
      args.addAll([
        '-vf',
        'scale=$outW:$outH:force_original_aspect_ratio=decrease,'
            'pad=$outW:$outH:(ow-iw)/2:(oh-ih)/2,'
            'setsar=1,'
            'fps=${p.fps}',
      ]);
    }

    // Video codec, rate control, and H.264 profile
    args.addAll([
      '-c:v', p.videoCodec,
      '-crf', p.crf.toString(),
      '-preset', p.preset,
      '-profile:v', p.profile,
      '-level:v', p.level,
      '-pix_fmt', p.pixFmt,
    ]);

    // BT.709 color metadata
    args.addAll([
      '-color_primaries', '1',
      '-color_trc', '1',
      '-colorspace', '1',
    ]);

    // Keyframe interval (2 seconds at target fps)
    args.addAll(['-g', p.keyframeInterval.toString()]);

    // VBV rate limiting (e.g. TikTok balanced)
    if (p.maxrateKbps != null && p.bufsizeKbps != null) {
      args.addAll([
        '-maxrate', '${p.maxrateKbps}k',
        '-bufsize', '${p.bufsizeKbps}k',
      ]);
    }

    // Audio
    args.addAll([
      '-c:a', 'aac',
      '-b:a', '${p.audioBitrate}k',
      '-ar', '44100',
    ]);

    // Fast start for streaming/upload
    args.addAll(['-movflags', '+faststart']);

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
    final command = buildCommandStatic(
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
