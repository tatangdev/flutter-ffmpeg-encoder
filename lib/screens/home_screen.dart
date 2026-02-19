import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/compression_result.dart';
import '../models/compression_settings.dart';
import '../models/video_info.dart';
import '../services/compression_service.dart';
import '../services/file_service.dart';
import '../services/permission_service.dart';
import '../utils/input_sanitizer.dart';
import '../widgets/compression_settings_form.dart';
import '../widgets/file_size_comparison.dart';
import '../widgets/video_info_card.dart';
import 'compression_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fileService = FileService();
  final _permissionService = PermissionService();
  late final CompressionService _compressionService;

  File? _selectedVideo;
  VideoInfo? _videoInfo;
  CompressionSettings _settings = const CompressionSettings();
  CompressionResult? _result;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _compressionService = CompressionService(_fileService);
    _checkPermissions();
  }

  @override
  void dispose() {
    _compressionService.dispose();
    super.dispose();
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
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs storage access to pick videos and save '
          'compressed files. Please grant the required permissions.',
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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissLoadingDialog() {
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickVideo() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      if (!_permissionsGranted) return;
    }

    _showLoadingDialog('Loading video file...');

    final file = await _fileService.pickVideo();
    if (file == null) {
      _dismissLoadingDialog();
      return;
    }

    final error = InputSanitizer.validateInputPath(file.path);
    if (error != null) {
      _dismissLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }

    _dismissLoadingDialog();
    _showLoadingDialog('Reading video information...');
    final info = await _fileService.getVideoInfo(file.path);
    _dismissLoadingDialog();

    setState(() {
      _selectedVideo = file;
      _videoInfo = info;
      _result = null;
    });
  }

  Future<void> _startCompression() async {
    if (_selectedVideo == null) return;

    // Let user choose output directory
    final outputDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose where to save compressed video',
    );
    if (outputDir == null || !mounted) return;

    final result = await Navigator.push<CompressionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CompressionScreen(
          inputPath: _selectedVideo!.path,
          outputDir: outputDir,
          settings: _settings,
          compressionService: _compressionService,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _result = result;
        if (result.originalDeleted) {
          _selectedVideo = null;
          _videoInfo = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Compressor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission warning
            if (!_permissionsGranted) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Storage permissions not granted',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
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
              ),
              const SizedBox(height: 16),
            ],

            // Pick video button
            FilledButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Select Video'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Video info
            if (_videoInfo != null) ...[
              VideoInfoCard(info: _videoInfo!),
              const SizedBox(height: 16),
            ],

            // Compression settings
            if (_selectedVideo != null) ...[
              CompressionSettingsForm(
                settings: _settings,
                onChanged: (s) => setState(() => _settings = s),
              ),
              const SizedBox(height: 16),

              // Compress button
              FilledButton.icon(
                onPressed: _startCompression,
                icon: const Icon(Icons.compress),
                label: const Text('Compress Video'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Result
            if (_result != null) FileSizeComparison(result: _result!),
          ],
        ),
      ),
    );
  }
}
