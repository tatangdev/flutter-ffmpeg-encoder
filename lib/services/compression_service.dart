import '../models/compression_settings.dart';

/// Static utility for building FFmpeg command strings.
class CompressionService {
  CompressionService._();

  /// Wraps a file path in single quotes, escaping internal single quotes.
  static String _quote(String path) => "'${path.replaceAll("'", r"'\''")}'";

  /// Builds the FFmpeg argument string from [settings].
  static String buildCommandStatic({
    required String inputPath,
    required String outputPath,
    required CompressionSettings settings,
  }) {
    final p = settings.resolvedPreset;
    final args = <String>[
      '-i', _quote(inputPath),
      '-y',
      '-threads', '0',
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

    args.add(_quote(outputPath));
    return args.join(' ');
  }
}
