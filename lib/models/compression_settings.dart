import '../utils/file_utils.dart' show enumByName;

enum ExportMode {
  custom('Custom'),
  socialMedia('Social Media');

  const ExportMode(this.label);
  final String label;
}

enum VideoPlatform {
  instagramPost('Instagram Post'),
  instagramReels('Instagram Reels'),
  tiktok('TikTok'),
  youtubeShorts('YouTube Shorts');

  const VideoPlatform(this.label);
  final String label;
}

enum CustomResolution {
  fhd(1080, 'FHD', '1080p Full HD'),
  qhd(1440, '2K', '1440p QHD'),
  uhd(2160, '4K', '2160p Ultra HD');

  const CustomResolution(this.shortSide, this.label, this.description);
  final int shortSide;
  final String label;
  final String description;
}

enum VideoAspectRatio {
  original(0, 0, 'Original'),
  landscape4x3(1440, 1080, '4:3'),
  portrait4x3(1080, 1440, '3:4'),
  landscape16x9(1920, 1080, '16:9'),
  portrait16x9(1080, 1920, '9:16');

  const VideoAspectRatio(this.width, this.height, this.label);
  final int width;
  final int height;
  final String label;

  bool get isOriginal => this == original;
}

enum VideoFit {
  contain('Fit', 'Fits entire video, adds black bars'),
  cover('Fill & Crop', 'Fills frame, crops overflow');

  const VideoFit(this.label, this.description);
  final String label;
  final String description;
}

enum VideoRotation {
  none(0, '0°', ''),
  cw90(90, '90°', 'transpose=1'),
  cw180(180, '180°', 'hflip,vflip'),
  cw270(270, '270°', 'transpose=2');

  const VideoRotation(this.degrees, this.label, this.ffmpegFilter);
  final int degrees;
  final String label;
  final String ffmpegFilter;

  /// Whether this rotation swaps width and height (90° / 270°).
  bool get swapsDimensions => this == cw90 || this == cw270;
}

enum QualityTier {
  best('Best Quality'),
  balanced('Balanced');

  const QualityTier(this.label);
  final String label;
}

class EncodingPreset {
  final String videoCodec;
  final int crf;
  final String preset;
  final String profile;
  final String level;
  final String pixFmt;
  final int audioBitrate;
  final int fps;
  final int keyframeInterval;
  final int? maxrateKbps;
  final int? bufsizeKbps;

  const EncodingPreset({
    required this.videoCodec,
    required this.crf,
    required this.preset,
    required this.profile,
    required this.level,
    required this.pixFmt,
    required this.audioBitrate,
    required this.fps,
    required this.keyframeInterval,
    this.maxrateKbps,
    this.bufsizeKbps,
  });
}

class PlatformPresets {
  PlatformPresets._();

  static EncodingPreset resolve(VideoPlatform platform, QualityTier tier) {
    return switch ((platform, tier)) {
      (VideoPlatform.instagramPost, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 18, preset: 'slow',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (VideoPlatform.instagramPost, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 23, preset: 'slower',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (VideoPlatform.instagramReels, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 18, preset: 'slow',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (VideoPlatform.instagramReels, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 23, preset: 'slower',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (VideoPlatform.tiktok, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 18, preset: 'slow',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 128, fps: 30, keyframeInterval: 60,
      ),
      (VideoPlatform.tiktok, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 24, preset: 'slower',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 128, fps: 30, keyframeInterval: 60,
        maxrateKbps: 10000, bufsizeKbps: 20000,
      ),
      (VideoPlatform.youtubeShorts, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 18, preset: 'slow',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (VideoPlatform.youtubeShorts, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 23, preset: 'slower',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
    };
  }
}

class CustomPresets {
  CustomPresets._();

  static EncodingPreset resolve(CustomResolution resolution, QualityTier tier) {
    return switch ((resolution, tier)) {
      (CustomResolution.fhd, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 18, preset: 'slow',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (CustomResolution.fhd, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 23, preset: 'medium',
        profile: 'high', level: '4.1', pixFmt: 'yuv420p',
        audioBitrate: 128, fps: 30, keyframeInterval: 60,
      ),
      (CustomResolution.qhd, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 18, preset: 'slow',
        profile: 'high', level: '5.0', pixFmt: 'yuv420p',
        audioBitrate: 256, fps: 30, keyframeInterval: 60,
      ),
      (CustomResolution.qhd, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 22, preset: 'medium',
        profile: 'high', level: '5.0', pixFmt: 'yuv420p',
        audioBitrate: 192, fps: 30, keyframeInterval: 60,
      ),
      (CustomResolution.uhd, QualityTier.best) => const EncodingPreset(
        videoCodec: 'libx264', crf: 17, preset: 'slow',
        profile: 'high', level: '5.1', pixFmt: 'yuv420p',
        audioBitrate: 320, fps: 30, keyframeInterval: 60,
      ),
      (CustomResolution.uhd, QualityTier.balanced) => const EncodingPreset(
        videoCodec: 'libx264', crf: 21, preset: 'medium',
        profile: 'high', level: '5.1', pixFmt: 'yuv420p',
        audioBitrate: 256, fps: 30, keyframeInterval: 60,
      ),
    };
  }
}

class CompressionSettings {
  final ExportMode exportMode;
  final VideoPlatform platform;
  final CustomResolution customResolution;
  final QualityTier tier;
  final VideoAspectRatio aspectRatio;
  final VideoFit fit;
  final VideoRotation rotation;
  final bool deleteOriginal;

  const CompressionSettings({
    this.exportMode = ExportMode.custom,
    this.platform = VideoPlatform.instagramPost,
    this.customResolution = CustomResolution.fhd,
    this.tier = QualityTier.best,
    this.aspectRatio = VideoAspectRatio.original,
    this.fit = VideoFit.contain,
    this.rotation = VideoRotation.none,
    this.deleteOriginal = false,
  });

  /// Rounds to nearest even number (required for H.264 yuv420p).
  static int _roundEven(int v) => v.isOdd ? v + 1 : v;

  /// Resolved output width in pixels. Returns 0 for original.
  int get resolvedWidth {
    if (aspectRatio.isOriginal) return 0;
    if (exportMode == ExportMode.socialMedia) {
      // Social media: width always capped at 1080
      return 1080;
    }
    // Custom: scale based on short side
    final scale = customResolution.shortSide / 1080;
    return _roundEven((aspectRatio.width * scale).round());
  }

  /// Resolved output height in pixels. Returns 0 for original.
  int get resolvedHeight {
    if (aspectRatio.isOriginal) return 0;
    if (exportMode == ExportMode.socialMedia) {
      // Social media: derive height from 1080 width + ratio
      return _roundEven(
        (1080 * aspectRatio.height / aspectRatio.width).round(),
      );
    }
    // Custom: scale based on short side
    final scale = customResolution.shortSide / 1080;
    return _roundEven((aspectRatio.height * scale).round());
  }

  EncodingPreset get resolvedPreset => exportMode == ExportMode.socialMedia
      ? PlatformPresets.resolve(platform, tier)
      : CustomPresets.resolve(customResolution, tier);

  Map<String, dynamic> toMap() {
    return {
      'settings_export_mode': exportMode.name,
      'settings_platform': platform.name,
      'settings_custom_resolution': customResolution.name,
      'settings_tier': tier.name,
      'settings_aspect_ratio': aspectRatio.name,
      'settings_fit': fit.name,
      'settings_rotation': rotation.name,
      'settings_delete_original': deleteOriginal ? 1 : 0,
    };
  }

  factory CompressionSettings.fromMap(Map<String, dynamic> map) {
    return CompressionSettings(
      exportMode: enumByName(ExportMode.values, map['settings_export_mode'] as String, ExportMode.custom),
      platform: enumByName(VideoPlatform.values, map['settings_platform'] as String, VideoPlatform.instagramPost),
      customResolution: enumByName(CustomResolution.values, map['settings_custom_resolution'] as String, CustomResolution.fhd),
      tier: enumByName(QualityTier.values, map['settings_tier'] as String, QualityTier.best),
      aspectRatio: enumByName(VideoAspectRatio.values, map['settings_aspect_ratio'] as String, VideoAspectRatio.original),
      fit: enumByName(VideoFit.values, map['settings_fit'] as String, VideoFit.contain),
      rotation: enumByName(VideoRotation.values, map['settings_rotation'] as String? ?? 'none', VideoRotation.none),
      deleteOriginal: (map['settings_delete_original'] as int) == 1,
    );
  }

  CompressionSettings copyWith({
    ExportMode? exportMode,
    VideoPlatform? platform,
    CustomResolution? customResolution,
    QualityTier? tier,
    VideoAspectRatio? aspectRatio,
    VideoFit? fit,
    VideoRotation? rotation,
    bool? deleteOriginal,
  }) {
    return CompressionSettings(
      exportMode: exportMode ?? this.exportMode,
      platform: platform ?? this.platform,
      customResolution: customResolution ?? this.customResolution,
      tier: tier ?? this.tier,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      fit: fit ?? this.fit,
      rotation: rotation ?? this.rotation,
      deleteOriginal: deleteOriginal ?? this.deleteOriginal,
    );
  }
}
