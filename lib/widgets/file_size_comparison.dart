import 'package:flutter/material.dart';

import '../models/compression_result.dart';
import '../theme/app_typography.dart';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.error_outline, color: theme.colorScheme.error),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.errorMessage ?? 'Compression failed',
                  style: AppTextStyles.textSmMedium.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                const Text('Compression Complete',
                    style: AppTextStyles.textLgSemibold),
              ],
            ),
            const SizedBox(height: 20),

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
                  style: AppTextStyles.textMdSemibold.copyWith(
                    color: AppColors.textBrand,
                  ),
                ),
                if (result.compressionDuration != null)
                  Text(
                    'Time: ${FileUtils.formatDuration(result.compressionDuration!)}',
                    style: AppTextStyles.textSmMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
            if (result.originalDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Original file deleted',
                  style: AppTextStyles.textSmMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
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
            Text(label, style: AppTextStyles.textSmMedium),
            Text(FileUtils.formatFileSize(size), style: AppTextStyles.textSmMedium.copyWith(
              color: AppColors.textPrimary,
            )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
