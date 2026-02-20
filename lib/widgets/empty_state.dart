import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onSelectVideo;

  const EmptyState({super.key, required this.onSelectVideo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                size: 48,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No video selected',
              style: AppTextStyles.displayXs,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a video from your device to configure\ncompression settings and reduce file size.',
              style: AppTextStyles.textMdRegular.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: onSelectVideo,
                icon: const Icon(Icons.video_library),
                label: const Text('Select Video'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
