enum VideoResolution {
  p480(640, 480, '480p'),
  p720(1280, 720, '720p'),
  p1080(1920, 1080, '1080p'),
  original(0, 0, 'Original');

  const VideoResolution(this.width, this.height, this.label);
  final int width;
  final int height;
  final String label;
}

enum VideoQuality {
  low(32, 'Low'),
  medium(28, 'Medium'),
  high(23, 'High');

  const VideoQuality(this.crf, this.label);
  final int crf;
  final String label;
}

enum CompressionPreset {
  ultrafast('ultrafast', 'Ultrafast'),
  fast('fast', 'Fast'),
  medium('medium', 'Medium'),
  slow('slow', 'Slow');

  const CompressionPreset(this.value, this.label);
  final String value;
  final String label;
}

class CompressionSettings {
  final VideoResolution resolution;
  final VideoQuality quality;
  final CompressionPreset preset;
  final String videoCodec;
  final String audioCodec;
  final int audioBitrate;
  final bool deleteOriginal;

  const CompressionSettings({
    this.resolution = VideoResolution.p720,
    this.quality = VideoQuality.medium,
    this.preset = CompressionPreset.medium,
    this.videoCodec = 'libx264',
    this.audioCodec = 'aac',
    this.audioBitrate = 128,
    this.deleteOriginal = false,
  });

  CompressionSettings copyWith({
    VideoResolution? resolution,
    VideoQuality? quality,
    CompressionPreset? preset,
    String? videoCodec,
    String? audioCodec,
    int? audioBitrate,
    bool? deleteOriginal,
  }) {
    return CompressionSettings(
      resolution: resolution ?? this.resolution,
      quality: quality ?? this.quality,
      preset: preset ?? this.preset,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      deleteOriginal: deleteOriginal ?? this.deleteOriginal,
    );
  }
}
