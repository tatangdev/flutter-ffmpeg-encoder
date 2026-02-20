import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../theme/app_typography.dart';
import '../utils/file_utils.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final files = <FileSystemEntity>[];

    // Scan known output directories for compressed files
    final dirs = <String>[];

    // Shared Movies directory
    const moviesPath = '/storage/emulated/0/Movies/VideoCompressor';
    if (await Directory(moviesPath).exists()) {
      dirs.add(moviesPath);
    }

    // App external storage
    final extDir = await getExternalStorageDirectory();
    if (extDir != null) {
      final compressedDir = Directory(p.join(extDir.path, 'compressed'));
      if (await compressedDir.exists()) {
        dirs.add(compressedDir.path);
      }
    }

    for (final dirPath in dirs) {
      final dir = Directory(dirPath);
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.mp4')) {
          files.add(entity);
        }
      }
    }

    // Sort by modification time (newest first)
    files.sort((a, b) {
      final aStat = a.statSync();
      final bStat = b.statSync();
      return bStat.modified.compareTo(aStat.modified);
    });

    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
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
                        child: const Icon(Icons.queue,
                            size: 40, color: AppColors.textQuaternary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No compressed videos yet',
                        style: AppTextStyles.textMdRegular.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _files.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = _files[index] as File;
                      final stat = file.statSync();
                      final name = p.basename(file.path);
                      final size = FileUtils.formatFileSize(stat.size);
                      final date = _formatDate(stat.modified);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.video_file,
                                    color: AppColors.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.textMdSemibold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$size  •  $date',
                                      style: AppTextStyles.textSmMedium.copyWith(
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.textQuaternary),
                                onPressed: () => _confirmDelete(file),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}'
        '-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?',
            style: AppTextStyles.textLgSemibold),
        content: Text(
          'Delete ${p.basename(file.path)}?',
          style: AppTextStyles.textMdRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await file.delete();
      _loadHistory();
    }
  }
}
