import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../models/compression_job.dart';
import '../models/compression_settings.dart';
import '../models/video_info.dart';
import '../services/compression_queue.dart';
import '../services/file_service.dart';
import '../services/permission_service.dart';
import '../utils/input_sanitizer.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/output_settings_card.dart';
import '../widgets/video_info_card.dart';

enum _PageState { empty, loading, ready }

class HomeScreen extends StatefulWidget {
  final CompressionQueue compressionQueue;
  final void Function(int) onSwitchTab;

  const HomeScreen({
    super.key,
    required this.compressionQueue,
    required this.onSwitchTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileService = FileService();
  final _permissionService = PermissionService();

  _PageState _pageState = _PageState.empty;
  String _loadingMessage = '';

  File? _selectedVideo;
  VideoInfo? _videoInfo;
  File? _thumbnail;
  CompressionSettings _settings = const CompressionSettings();
  bool _permissionsGranted = false;
  String? _outputDir;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _initOutputDir();
  }

  Future<void> _initOutputDir() async {
    final dir = await _fileService.getOutputDirectory();
    if (mounted) setState(() => _outputDir = dir);
  }

  Future<void> _changeOutputDir() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose output directory',
    );
    if (dir != null && mounted) {
      setState(() => _outputDir = dir);
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await _permissionService.hasStoragePermissions();
    setState(() => _permissionsGranted = granted);
    if (!granted && mounted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissions Required',
            style: AppTextStyles.textLgSemibold),
        content: Text(
          'This app needs storage access to pick videos and save '
          'compressed files. Please grant the required permissions.',
          style: AppTextStyles.textMdRegular.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _requestPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final granted = await _permissionService.requestStoragePermissions();
    setState(() => _permissionsGranted = granted);
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Some permissions were denied. '
              'You can grant them in app settings.'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) return;
    }

    final file = await _fileService.pickVideo();
    if (file == null) return;

    final error = InputSanitizer.validateInputPath(file.path);
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }

    setState(() {
      _pageState = _PageState.loading;
      _loadingMessage = 'Reading video information...';
    });

    final info = await _fileService.getVideoInfo(file.path);
    final thumb = await _fileService.extractThumbnail(file.path);

    setState(() {
      _selectedVideo = file;
      _videoInfo = info;
      _thumbnail = thumb;
      _pageState = _PageState.ready;
    });
  }

  Future<void> _startCompression() async {
    if (_selectedVideo == null || _outputDir == null) return;

    final confirmed = await _showConfirmationDialog();
    if (confirmed != true || !mounted) return;

    final job = CompressionJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      inputPath: _selectedVideo!.path,
      outputDir: _outputDir!,
      fileName: p.basename(_selectedVideo!.path),
      settings: _settings,
      thumbnailFile: _thumbnail,
    );

    widget.compressionQueue.addJob(job);
    _resetToEmpty();
    widget.onSwitchTab(1);
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Compression',
            style: AppTextStyles.textLgSemibold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow('File', _videoInfo?.fileName ?? ''),
            _summaryRow('Size', _videoInfo?.formattedSize ?? ''),
            _summaryRow('Mode', _settings.exportMode.label),
            _summaryRow('Quality', _settings.tier.label),
            _summaryRow('Output', _outputDir ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Compress'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.textSmMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _resetToEmpty() {
    setState(() {
      _selectedVideo = null;
      _videoInfo = null;
      _thumbnail = null;
      _settings = const CompressionSettings();
      _pageState = _PageState.empty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pageState == _PageState.empty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resetToEmpty();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Video Compressor'),
          actions: [
            if (_pageState == _PageState.ready)
              TextButton.icon(
                onPressed: _pickVideo,
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: const Text('Change'),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (!_permissionsGranted)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildPermissionWarning(),
          ),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStateContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildStateContent() {
    return switch (_pageState) {
      _PageState.empty => EmptyState(
          key: const ValueKey('empty'),
          onSelectVideo: _pickVideo,
        ),
      _PageState.loading => LoadingState(
          key: const ValueKey('loading'),
          message: _loadingMessage,
        ),
      _PageState.ready => _buildReadyContent(),
    };
  }

  Widget _buildReadyContent() {
    return SingleChildScrollView(
      key: const ValueKey('ready'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_videoInfo != null) ...[
            VideoInfoCard(info: _videoInfo!, thumbnail: _thumbnail),
            const SizedBox(height: 16),
          ],

          OutputSettingsCard(
            settings: _settings,
            onChanged: (s) => setState(() => _settings = s),
            thumbnailFile: _thumbnail,
            videoWidth: _videoInfo?.width,
            videoHeight: _videoInfo?.height,
          ),
          const SizedBox(height: 16),

          // Output directory
          _buildOutputDirCard(),
          const SizedBox(height: 16),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _startCompression,
              icon: const Icon(Icons.compress),
              label: const Text('Compress Video'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOutputDirCard() {
    return Card(
      child: InkWell(
        onTap: _changeOutputDir,
        borderRadius: BorderRadius.circular(24),
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
                child: const Icon(Icons.folder_outlined,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Output Directory',
                        style: AppTextStyles.textMdSemibold),
                    const SizedBox(height: 2),
                    Text(
                      _outputDir ?? 'Loading...',
                      style: AppTextStyles.textSmMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textQuaternary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Storage permissions not granted',
                style: AppTextStyles.textSmMedium.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: _requestPermissions,
              child: const Text('Grant'),
            ),
          ],
        ),
      ),
    );
  }
}
