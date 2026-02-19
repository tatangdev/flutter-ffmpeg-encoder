import 'constants.dart';

class InputSanitizer {
  InputSanitizer._();

  static final _dangerousChars = RegExp(r'[;&|`$(){}[\]!#~]');

  /// Validates an input file path for security.
  /// Returns null if valid, or an error message if invalid.
  static String? validateInputPath(String path) {
    if (path.isEmpty) return 'Path cannot be empty';
    if (path.contains('..')) return 'Path traversal not allowed';
    if (_dangerousChars.hasMatch(path)) return 'Invalid characters in path';

    final ext = path.split('.').last.toLowerCase();
    if (!AppConstants.supportedExtensions.contains(ext)) {
      return 'Unsupported format: $ext';
    }

    return null;
  }

  /// Sanitizes a file name by replacing unsafe characters with underscores.
  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-.]'), '_');
  }
}
