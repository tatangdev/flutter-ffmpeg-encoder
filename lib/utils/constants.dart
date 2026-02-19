class AppConstants {
  AppConstants._();

  static const String appName = 'Video Compressor';
  static const String outputDirectory = 'compressed';
  static const String outputSuffix = '_compressed';
  static const String defaultOutputFormat = 'mp4';
  static const int defaultAudioBitrate = 128;

  static const List<String> supportedExtensions = [
    'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', '3gp',
  ];
}
