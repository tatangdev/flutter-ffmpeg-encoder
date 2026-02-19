class CompressionResult {
  final bool success;
  final String? outputPath;
  final int? originalSizeBytes;
  final int? compressedSizeBytes;
  final Duration? compressionDuration;
  final String? errorMessage;
  final int? ffmpegReturnCode;
  final bool originalDeleted;

  const CompressionResult({
    required this.success,
    this.outputPath,
    this.originalSizeBytes,
    this.compressedSizeBytes,
    this.compressionDuration,
    this.errorMessage,
    this.ffmpegReturnCode,
    this.originalDeleted = false,
  });

  double get compressionRatio {
    if (originalSizeBytes == null ||
        compressedSizeBytes == null ||
        originalSizeBytes == 0) {
      return 0.0;
    }
    return compressedSizeBytes! / originalSizeBytes!;
  }

  double get savedPercentage => (1 - compressionRatio) * 100;
}
