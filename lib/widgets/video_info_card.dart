import 'package:flutter/material.dart';

import '../models/video_info.dart';
import '../theme/app_typography.dart';
import '../utils/file_utils.dart';

class VideoInfoCard extends StatelessWidget {
  final VideoInfo info;

  const VideoInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Details',
              style: AppTextStyles.textLgSemibold,
            ),
            const SizedBox(height: 16),
            _row(Icons.insert_drive_file, 'File', info.fileName),
            _row(Icons.sd_storage, 'Size', info.formattedSize),
            if (info.duration != null)
              _row(Icons.timer, 'Duration',
                  FileUtils.formatDuration(info.duration!)),
            _row(Icons.aspect_ratio, 'Resolution', info.resolution),
            if (info.videoCodec != null)
              _row(Icons.videocam, 'Codec', info.videoCodec!),
            if (info.format != null)
              _row(Icons.folder_open, 'Format', info.format!),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Text('$label: ', style: AppTextStyles.textSmSemibold.copyWith(
            color: AppColors.textPrimary,
          )),
          Expanded(child: Text(value, style: AppTextStyles.textSmMedium, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
