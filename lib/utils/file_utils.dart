import 'package:path/path.dart' as p;

import 'constants.dart';
import 'input_sanitizer.dart';

/// Safely resolves an enum value by [name], returning [fallback] if not found.
T enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Wraps a file path in single quotes, escaping internal single quotes.
/// Used to safely pass paths to FFmpeg commands.
String shellQuote(String path) => "'${path.replaceAll("'", r"'\''")}'";

class FileUtils {
  FileUtils._();

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Generates a unique output path in [outputDir] based on the input file name.
  static String generateOutputPath(String inputPath, String outputDir) {
    final baseName = p.basenameWithoutExtension(inputPath);
    final sanitized = InputSanitizer.sanitizeFileName(baseName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(
      outputDir,
      '$sanitized${AppConstants.outputSuffix}_$timestamp.${AppConstants.defaultOutputFormat}',
    );
  }
}
