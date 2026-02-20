import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/compression_job.dart';
import '../models/compression_settings.dart';
import '../services/compression_queue.dart';
import '../theme/app_typography.dart';
import '../utils/file_utils.dart';

class QueueScreen extends StatefulWidget {
  final CompressionQueue compressionQueue;

  const QueueScreen({super.key, required this.compressionQueue});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  void initState() {
    super.initState();
    widget.compressionQueue.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    widget.compressionQueue.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.compressionQueue.jobs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
      ),
      body: jobs.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return KeyedSubtree(
                  key: ValueKey(job.id),
                  child: _buildJobCard(job),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: FaIcon(FontAwesomeIcons.listUl,
                size: 36, color: AppColors.textQuaternary)),
          ),
          const SizedBox(height: 16),
          Text(
            'No compression jobs',
            style: AppTextStyles.textMdSemibold.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start compressing a video to see progress here',
            style: AppTextStyles.textSmMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(CompressionJob job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: thumbnail + info + action button
            Row(
              children: [
                _buildThumbnail(job),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.fileName,
                        style: AppTextStyles.textMdSemibold,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusLabel(job),
                        style: AppTextStyles.textSmMedium.copyWith(
                          color: _statusColor(job.status),
                        ),
                      ),
                    ],
                  ),
                ),
                if (job.status == JobStatus.compressing)
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.circleXmark,
                        size: 22, color: AppColors.textQuaternary),
                    onPressed: () => _confirmCancel(job),
                  ),
                if (job.status == JobStatus.completed ||
                    job.status == JobStatus.failed ||
                    job.status == JobStatus.cancelled)
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark,
                        size: 22, color: AppColors.textQuaternary),
                    onPressed: () =>
                        widget.compressionQueue.removeJob(job.id),
                  ),
              ],
            ),

            // Progress bar (only while compressing)
            if (job.status == JobStatus.compressing) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: job.progress),
              ),
              const SizedBox(height: 4),
              Text(
                '${(job.progress * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.textSmMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],

            // Result summary (completed)
            if (job.status == JobStatus.completed &&
                job.result != null) ...[
              const SizedBox(height: 8),
              Text(
                '${FileUtils.formatFileSize(job.result!.originalSizeBytes ?? 0)}'
                ' \u2192 ${FileUtils.formatFileSize(job.result!.compressedSizeBytes ?? 0)}'
                '  \u2022  Saved ${job.result!.savedPercentage.toStringAsFixed(1)}%',
                style: AppTextStyles.textSmMedium.copyWith(
                  color: AppColors.textBrand,
                ),
              ),
            ],

            // Error message (failed)
            if (job.status == JobStatus.failed &&
                job.result?.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                job.result!.errorMessage!,
                style: AppTextStyles.textSmMedium.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],

            // Cancelled
            if (job.status == JobStatus.cancelled) ...[
              const SizedBox(height: 8),
              Text(
                'Compression was cancelled',
                style: AppTextStyles.textSmMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],

            // Details row
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _buildDetailsRow(job),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(CompressionJob job) {
    final isFinished = job.status == JobStatus.completed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or placeholder
            if (job.thumbnailFile != null)
              Image.file(
                job.thumbnailFile!,
                fit: BoxFit.cover,
                cacheWidth: 96,
              )
            else
              Container(
                color: AppColors.bgSecondary,
                child: const Center(child: FaIcon(FontAwesomeIcons.video,
                    size: 20, color: AppColors.textTertiary)),
              ),

            // Checkmark overlay when completed
            if (isFinished)
              Container(
                color: AppColors.accent.withValues(alpha: 0.7),
                child: const Center(child: FaIcon(FontAwesomeIcons.check,
                    color: Colors.white, size: 20)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsRow(CompressionJob job) {
    final settings = job.settings;
    final quality = settings.tier.label;

    String preset;
    if (settings.exportMode == ExportMode.custom) {
      preset = settings.customResolution.description;
    } else {
      preset = settings.platform.label;
    }

    return Row(
      children: [
        Expanded(child: _detailChip(FontAwesomeIcons.sliders, preset)),
        Expanded(child: _detailChip(FontAwesomeIcons.solidStar, quality)),
        Expanded(child: _detailChip(FontAwesomeIcons.folder, _shortenPath(job.outputDir))),
      ],
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Row(
      children: [
        FaIcon(icon, size: 12, color: AppColors.textQuaternary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.textSmMedium.copyWith(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  String _shortenPath(String path) {
    final parts = path.split('/');
    if (parts.length <= 3) return path;
    return '.../${parts.sublist(parts.length - 2).join('/')}';
  }

  Future<void> _confirmCancel(CompressionJob job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Compression',
            style: AppTextStyles.textLgSemibold),
        content: Text(
          'Are you sure you want to cancel compressing "${job.fileName}"?',
          style: AppTextStyles.textMdRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.compressionQueue.cancelJob(job.id);
    }
  }

  String _statusLabel(CompressionJob job) {
    return switch (job.status) {
      JobStatus.pending => 'Waiting...',
      JobStatus.compressing => 'Compressing...',
      JobStatus.completed => 'Completed',
      JobStatus.failed => 'Failed',
      JobStatus.cancelled => 'Cancelled',
    };
  }

  Color _statusColor(JobStatus status) {
    return switch (status) {
      JobStatus.pending => AppColors.textTertiary,
      JobStatus.compressing => AppColors.accent,
      JobStatus.completed => AppColors.textBrand,
      JobStatus.failed => Theme.of(context).colorScheme.error,
      JobStatus.cancelled => AppColors.textTertiary,
    };
  }
}
