import 'package:flutter_test/flutter_test.dart';

import 'package:devcoder/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer.validateInputPath', () {
    test('returns null for valid mp4 path', () {
      expect(InputSanitizer.validateInputPath('/storage/video.mp4'), isNull);
    });

    test('returns null for valid mkv path', () {
      expect(
          InputSanitizer.validateInputPath('/storage/movie.mkv'), isNull);
    });

    test('rejects empty path', () {
      expect(InputSanitizer.validateInputPath(''), isNotNull);
    });

    test('rejects path traversal with ..', () {
      expect(
        InputSanitizer.validateInputPath('/foo/../etc/passwd'),
        contains('traversal'),
      );
    });

    test('rejects shell metacharacters', () {
      expect(InputSanitizer.validateInputPath('/foo; rm -rf /'), isNotNull);
      expect(InputSanitizer.validateInputPath('/foo | cat'), isNotNull);
      expect(InputSanitizer.validateInputPath('/foo`whoami`'), isNotNull);
      expect(InputSanitizer.validateInputPath(r'/foo$(cmd)'), isNotNull);
    });

    test('rejects unsupported extensions', () {
      expect(InputSanitizer.validateInputPath('/foo/bar.exe'), isNotNull);
      expect(InputSanitizer.validateInputPath('/foo/bar.txt'), isNotNull);
    });

    test('accepts all supported video formats', () {
      for (final ext in ['mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm', '3gp']) {
        expect(
          InputSanitizer.validateInputPath('/storage/video.$ext'),
          isNull,
          reason: '$ext should be accepted',
        );
      }
    });
  });

  group('InputSanitizer.sanitizeFileName', () {
    test('replaces unsafe characters with underscores', () {
      expect(
        InputSanitizer.sanitizeFileName('my;video|file.mp4'),
        'my_video_file.mp4',
      );
    });

    test('keeps safe characters intact', () {
      expect(
        InputSanitizer.sanitizeFileName('my-video_file.mp4'),
        'my-video_file.mp4',
      );
    });
  });
}
