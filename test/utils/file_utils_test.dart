import 'package:flutter_test/flutter_test.dart';

import 'package:devcoder/utils/file_utils.dart';

void main() {
  group('FileUtils.formatFileSize', () {
    test('formats bytes', () {
      expect(FileUtils.formatFileSize(500), '500 B');
    });

    test('formats kilobytes', () {
      expect(FileUtils.formatFileSize(1536), '1.5 KB');
    });

    test('formats megabytes', () {
      expect(FileUtils.formatFileSize(10485760), '10.0 MB');
    });

    test('formats gigabytes', () {
      expect(FileUtils.formatFileSize(1610612736), '1.50 GB');
    });
  });

  group('FileUtils.formatDuration', () {
    test('formats seconds only', () {
      expect(FileUtils.formatDuration(const Duration(seconds: 45)), '45s');
    });

    test('formats minutes and seconds', () {
      expect(
        FileUtils.formatDuration(const Duration(minutes: 3, seconds: 15)),
        '3m 15s',
      );
    });

    test('formats hours, minutes and seconds', () {
      expect(
        FileUtils.formatDuration(
            const Duration(hours: 1, minutes: 30, seconds: 5)),
        '1h 30m 5s',
      );
    });
  });

  group('FileUtils.generateOutputPath', () {
    test('generates path in output directory with compressed suffix', () {
      final path = FileUtils.generateOutputPath(
        '/storage/my_video.mp4',
        '/output',
      );
      expect(path, contains('/output/'));
      expect(path, contains('my_video_compressed_'));
      expect(path, endsWith('.mp4'));
    });
  });
}
