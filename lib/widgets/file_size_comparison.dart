import 'package:flutter/material.dart';

import '../models/compression_result.dart';
import '../utils/file_utils.dart';

class FileSizeComparison extends StatelessWidget {
  final CompressionResult result;

  const FileSizeComparison({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!result.success) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.errorMessage ?? 'Compression failed',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final originalSize = result.originalSizeBytes ?? 0;
    final compressedSize = result.compressedSizeBytes ?? 0;
    final maxSize = originalSize > compressedSize ? originalSize : compressedSize;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Compression Complete',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Original size bar
            _sizeBar(
              context,
              label: 'Original',
              size: originalSize,
              maxSize: maxSize,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 8),

            // Compressed size bar
            _sizeBar(
              context,
              label: 'Compressed',
              size: compressedSize,
              maxSize: maxSize,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved ${result.savedPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (result.compressionDuration != null)
                  Text(
                    'Time: ${FileUtils.formatDuration(result.compressionDuration!)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            if (result.originalDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Original file deleted',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sizeBar(
    BuildContext context, {
    required String label,
    required int size,
    required int maxSize,
    required Color color,
  }) {
    final fraction = maxSize > 0 ? size / maxSize : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(FileUtils.formatFileSize(size)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
