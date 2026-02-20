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

  Map<String, dynamic> toMap() {
    return {
      'result_success': success ? 1 : 0,
      'result_output_path': outputPath,
      'result_original_size_bytes': originalSizeBytes,
      'result_compressed_size_bytes': compressedSizeBytes,
      'result_compression_duration_ms': compressionDuration?.inMilliseconds,
      'result_error_message': errorMessage,
      'result_ffmpeg_return_code': ffmpegReturnCode,
      'result_original_deleted': originalDeleted ? 1 : 0,
    };
  }

  factory CompressionResult.fromMap(Map<String, dynamic> map) {
    return CompressionResult(
      success: (map['result_success'] as int) == 1,
      outputPath: map['result_output_path'] as String?,
      originalSizeBytes: map['result_original_size_bytes'] as int?,
      compressedSizeBytes: map['result_compressed_size_bytes'] as int?,
      compressionDuration: map['result_compression_duration_ms'] != null
          ? Duration(milliseconds: map['result_compression_duration_ms'] as int)
          : null,
      errorMessage: map['result_error_message'] as String?,
      ffmpegReturnCode: map['result_ffmpeg_return_code'] as int?,
      originalDeleted: (map['result_original_deleted'] as int?) == 1,
    );
  }

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
