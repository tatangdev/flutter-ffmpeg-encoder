import 'dart:async';

import 'package:flutter/material.dart';

import '../models/compression_result.dart';
import '../models/compression_settings.dart';
import '../services/compression_service.dart';
import '../theme/app_typography.dart';
import '../utils/file_utils.dart';

class CompressionScreen extends StatefulWidget {
  final String inputPath;
  final String outputDir;
  final CompressionSettings settings;
  final CompressionService compressionService;

  const CompressionScreen({
    super.key,
    required this.inputPath,
    required this.outputDir,
    required this.settings,
    required this.compressionService,
  });

  @override
  State<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends State<CompressionScreen> {
  double _progress = 0.0;
  bool _isCompressing = true;
  CompressionResult? _result;
  late StreamSubscription<double> _progressSub;
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _progressSub =
        widget.compressionService.progressStream.listen((progress) {
      setState(() => _progress = progress);
    });
    _startCompression();
  }

  @override
  void dispose() {
    _progressSub.cancel();
    super.dispose();
  }

  Future<void> _startCompression() async {
    final result = await widget.compressionService.compress(
      inputPath: widget.inputPath,
      outputDir: widget.outputDir,
      settings: widget.settings,
    );
    _stopwatch.stop();
    if (mounted) {
      setState(() {
        _result = result;
        _isCompressing = false;
      });
    }
  }

  Future<void> _cancel() async {
    await widget.compressionService.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCompressing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isCompressing ? 'Compressing...' : 'Done'),
          automaticallyImplyLeading: !_isCompressing,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: _isCompressing ? _buildProgressView() : _buildResultView(),
        ),
      ),
    );
  }

  Widget _buildProgressView() {
    final elapsed = _stopwatch.elapsed;
    Duration? remaining;
    if (_progress > 0.05) {
      final estimatedTotalMs = elapsed.inMilliseconds / _progress;
      remaining = Duration(
        milliseconds: (estimatedTotalMs - elapsed.inMilliseconds).round(),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.compress, size: 40, color: AppColors.accent),
        ),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${(_progress * 100).toStringAsFixed(1)}%',
          style: AppTextStyles.displayXs,
        ),
        const SizedBox(height: 8),
        if (remaining != null)
          Text(
            'Estimated time remaining: ${FileUtils.formatDuration(remaining)}',
            style: AppTextStyles.textSmMedium,
          ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildResultView() {
    final result = _result!;
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: result.success
                ? AppColors.accent.withValues(alpha: 0.1)
                : theme.colorScheme.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            result.success ? Icons.check_circle : Icons.error,
            size: 40,
            color: result.success ? AppColors.accent : theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          result.success ? 'Compression Successful!' : 'Compression Failed',
          style: AppTextStyles.displayXs,
        ),
        const SizedBox(height: 16),
        if (result.success) ...[
          Text(
            '${FileUtils.formatFileSize(result.originalSizeBytes ?? 0)}'
            ' -> ${FileUtils.formatFileSize(result.compressedSizeBytes ?? 0)}',
            style: AppTextStyles.textMdRegular,
          ),
          const SizedBox(height: 8),
          Text(
            'Saved ${result.savedPercentage.toStringAsFixed(1)}%',
            style: AppTextStyles.textLgSemibold.copyWith(
              color: AppColors.textBrand,
            ),
          ),
          if (result.outputPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Saved to:\n${result.outputPath}',
                style: AppTextStyles.textSmMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
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
        ] else ...[
          Text(
            result.errorMessage ?? 'An unknown error occurred',
            style: AppTextStyles.textMdRegular.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.pop(context, result),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
