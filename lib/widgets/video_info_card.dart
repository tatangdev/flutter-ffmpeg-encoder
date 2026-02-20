import 'dart:io';

import 'package:flutter/material.dart';

import '../models/video_info.dart';
import '../theme/app_typography.dart';
import '../utils/file_utils.dart';

class VideoInfoCard extends StatelessWidget {
  final VideoInfo info;
  final File? thumbnail;

  const VideoInfoCard({super.key, required this.info, this.thumbnail});

  @override
  Widget build(BuildContext context) {
    final stats = <String>[
      info.formattedSize,
      if (info.duration != null) FileUtils.formatDuration(info.duration!),
      info.resolution,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: thumbnail != null
                    ? Image.file(thumbnail!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.bgSecondary,
                        child: const Icon(Icons.videocam,
                            size: 24, color: AppColors.textTertiary),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // File name + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.fileName,
                    style: AppTextStyles.textMdSemibold,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stats.join(' \u00b7 '),
                    style: AppTextStyles.textSmMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
