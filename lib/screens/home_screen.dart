import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../models/compression_job.dart';
import '../models/compression_settings.dart';
import '../models/draft.dart';
import '../models/video_info.dart';
import '../services/compression_queue.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../services/permission_service.dart';
import '../utils/input_sanitizer.dart';
import '../theme/app_typography.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/output_settings_card.dart';
import '../widgets/video_info_card.dart';

enum _PageState { empty, draft, loading, ready }

class HomeScreen extends StatefulWidget {
  final CompressionQueue compressionQueue;
  final DatabaseService databaseService;
  final void Function(int) onSwitchTab;

  const HomeScreen({
    super.key,
    required this.compressionQueue,
    required this.databaseService,
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

  // Draft state
  Draft? _draft;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadDraft();
    _permissionService.requestNotificationPermission();
  }

  Future<void> _loadDraft() async {
    final row = await widget.databaseService.loadDraft();
    if (row != null && mounted) {
      final draft = Draft.fromMap(row);
      // Verify the video file still exists
      if (await File(draft.videoInfo.filePath).exists()) {
        setState(() {
          _draft = draft;
          _pageState = _PageState.draft;
        });
      } else {
        await widget.databaseService.deleteDraft();
      }
    }
  }

  Future<void> _saveDraft() async {
    if (_videoInfo == null) return;
    final draft = Draft(
      videoInfo: _videoInfo!,
      thumbnailPath: _thumbnail?.path,
      outputDir: _outputDir,
      settings: _settings,
    );
    await widget.databaseService.saveDraft(draft.toMap());
    setState(() {
      _draft = draft;
    });
  }

  Future<void> _resumeDraft() async {
    if (_draft == null) return;

    setState(() {
      _pageState = _PageState.loading;
      _loadingMessage = 'Restoring draft...';
    });

    final draft = _draft!;
    final file = File(draft.videoInfo.filePath);

    if (!await file.exists()) {
      await widget.databaseService.deleteDraft();
      if (mounted) {
        setState(() {
          _draft = null;
          _pageState = _PageState.empty;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video file no longer exists')),
        );
      }
      return;
    }

    // Re-extract info and thumbnail in parallel for freshness
    final results = await Future.wait([
      _fileService.getVideoInfo(file.path),
      _fileService.extractThumbnail(file.path),
    ]);

    if (mounted) {
      setState(() {
        _selectedVideo = file;
        _videoInfo = results[0] as VideoInfo;
        _thumbnail = results[1] as File?;
        _settings = draft.settings;
        _outputDir = draft.outputDir;
        _pageState = _PageState.ready;
      });
    }
  }

  Future<void> _discardDraft() async {
    await widget.databaseService.deleteDraft();
    if (mounted) {
      setState(() {
        _draft = null;
        _pageState = _PageState.empty;
      });
    }
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
    if (!mounted) return;
    setState(() => _permissionsGranted = granted);
    if (!granted) {
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
    if (!mounted) return;
    setState(() => _permissionsGranted = granted);
    if (!granted) {
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

    // Clear any existing draft when picking a new video
    await widget.databaseService.deleteDraft();

    setState(() {
      _draft = null;
      _pageState = _PageState.loading;
      _loadingMessage = 'Reading video information...';
    });

    final results = await Future.wait([
      _fileService.getVideoInfo(file.path),
      _fileService.extractThumbnail(file.path),
    ]);

    if (!mounted) return;
    setState(() {
      _selectedVideo = file;
      _videoInfo = results[0] as VideoInfo;
      _thumbnail = results[1] as File?;
      _settings = const CompressionSettings();
      _pageState = _PageState.ready;
    });
  }

  Future<void> _startCompression() async {
    if (_selectedVideo == null) return;
    if (_outputDir == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set an output directory first'),
          ),
        );
      }
      return;
    }

    final confirmed = await _showConfirmationDialog();
    if (confirmed != true || !mounted) return;

    final job = CompressionJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      inputPath: _selectedVideo!.path,
      outputDir: _outputDir!,
      fileName: p.basename(_selectedVideo!.path),
      settings: _settings,
      thumbnailFile: _thumbnail,
      durationMs: _videoInfo?.duration?.inMilliseconds,
    );

    widget.compressionQueue.addJob(job);
    await widget.databaseService.deleteDraft();
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
      _draft = null;
      _pageState = _PageState.empty;
    });
  }

  void _goBackFromReady() {
    _saveDraft();
    setState(() {
      _pageState = _PageState.draft;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pageState == _PageState.empty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_pageState == _PageState.ready) {
          _goBackFromReady();
        } else if (_pageState == _PageState.draft) {
          _discardDraft();
        } else {
          _resetToEmpty();
        }
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
      _PageState.draft => _buildDraftContent(),
      _PageState.loading => LoadingState(
          key: const ValueKey('loading'),
          message: _loadingMessage,
        ),
      _PageState.ready => _buildReadyContent(),
    };
  }

  Widget _buildDraftContent() {
    final draft = _draft;
    if (draft == null) return const SizedBox.shrink();

    return Center(
      key: const ValueKey('draft'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Draft card
            Card(
              child: InkWell(
                onTap: _resumeDraft,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: draft.thumbnailFile != null
                              ? Image.file(draft.thumbnailFile!,
                                  fit: BoxFit.cover, cacheWidth: 112)
                              : Container(
                                  color: AppColors.bgSecondary,
                                  child: const Icon(Icons.videocam,
                                      size: 28,
                                      color: AppColors.textQuaternary),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    draft.videoInfo.fileName,
                                    style: AppTextStyles.textMdSemibold,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgTertiary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Draft',
                                    style: AppTextStyles.textSmMedium.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${draft.videoInfo.formattedSize} · ${draft.settings.exportMode.label}',
                              style: AppTextStyles.textSmMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
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
            ),
            const SizedBox(height: 16),
            // Actions
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _discardDraft,
                      child: const Text('Discard'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library, size: 20),
                      label: const Text('New Video'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                      _outputDir ?? 'Tap to select output directory',
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
