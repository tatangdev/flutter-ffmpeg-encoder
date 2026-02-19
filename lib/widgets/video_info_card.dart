import 'package:flutter/material.dart';

import '../models/video_info.dart';
import '../utils/file_utils.dart';

class VideoInfoCard extends StatelessWidget {
  final VideoInfo info;

  const VideoInfoCard({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
