import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_typography.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _storageGranted = false;
  bool _manageStorageGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final storage = await Permission.storage.isGranted;
    final videos = await Permission.videos.isGranted;
    final manage = await Permission.manageExternalStorage.isGranted;

    setState(() {
      _storageGranted = storage || videos;
      _manageStorageGranted = manage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Permissions',
              style: AppTextStyles.textSmSemibold.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              _storageGranted ? Icons.check_circle : Icons.cancel,
              color: _storageGranted ? AppColors.textPrimary : AppColors.textQuaternary,
            ),
            title: const Text('Storage / Media Access',
                style: AppTextStyles.textMdSemibold),
            subtitle: Text(
              _storageGranted ? 'Granted' : 'Not granted',
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: _storageGranted
                ? null
                : TextButton(
                    onPressed: () async {
                      await Permission.videos.request();
                      _checkPermissions();
                    },
                    child: const Text('Grant'),
                  ),
          ),
          ListTile(
            leading: Icon(
              _manageStorageGranted ? Icons.check_circle : Icons.cancel,
              color: _manageStorageGranted ? AppColors.textPrimary : AppColors.textQuaternary,
            ),
            title: const Text('All Files Access',
                style: AppTextStyles.textMdSemibold),
            subtitle: Text(
              _manageStorageGranted
                  ? 'Granted'
                  : 'Needed to save to any folder',
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: _manageStorageGranted
                ? null
                : TextButton(
                    onPressed: () async {
                      await Permission.manageExternalStorage.request();
                      _checkPermissions();
                    },
                    child: const Text('Grant'),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings',
                style: AppTextStyles.textMdSemibold),
            subtitle: Text(
              'Open system app settings',
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            onTap: openAppSettings,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'About',
              style: AppTextStyles.textSmSemibold.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.compress,
                color: Theme.of(context).colorScheme.primary),
            title: const Text('Video Compressor',
                style: AppTextStyles.textMdSemibold),
            subtitle: Text(
              'Version 1.0.0',
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Features', style: AppTextStyles.textMdSemibold),
                    const SizedBox(height: 16),
                    _featureRow(Icons.compress, 'Compress videos with H.264'),
                    _featureRow(
                        Icons.tune, 'Configurable resolution, quality & speed'),
                    _featureRow(Icons.folder_open, 'Choose output directory'),
                    _featureRow(
                        Icons.speed, 'Asynchronous compression with progress'),
                    _featureRow(
                        Icons.delete_outline, 'Optional original file deletion'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Powered By', style: AppTextStyles.textMdSemibold),
                    const SizedBox(height: 16),
                    _featureRow(Icons.movie, 'FFmpeg 8.0'),
                    _featureRow(Icons.flutter_dash, 'Flutter'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _featureRow(IconData icon, String text) {
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
        Expanded(
          child: Text(text, style: AppTextStyles.textSmMedium),
        ),
      ],
    ),
  );
}
