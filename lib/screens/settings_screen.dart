import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  bool _notificationGranted = false;
  bool _batteryOptimized = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final storage = await Permission.storage.isGranted;
    final videos = await Permission.videos.isGranted;
    final manage = await Permission.manageExternalStorage.isGranted;
    final notification = await Permission.notification.isGranted;
    final battery =
        await FlutterForegroundTask.isIgnoringBatteryOptimizations;

    if (!mounted) return;
    setState(() {
      _storageGranted = storage || videos;
      _manageStorageGranted = manage;
      _notificationGranted = notification;
      _batteryOptimized = battery;
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
            leading: FaIcon(
              _storageGranted ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.solidCircleXmark,
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
            leading: FaIcon(
              _manageStorageGranted ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.solidCircleXmark,
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
          ListTile(
            leading: FaIcon(
              _notificationGranted ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.solidCircleXmark,
              color: _notificationGranted ? AppColors.textPrimary : AppColors.textQuaternary,
            ),
            title: const Text('Notifications',
                style: AppTextStyles.textMdSemibold),
            subtitle: Text(
              _notificationGranted
                  ? 'Granted'
                  : 'Needed for compression progress',
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: _notificationGranted
                ? null
                : TextButton(
                    onPressed: () async {
                      await Permission.notification.request();
                      _checkPermissions();
                    },
                    child: const Text('Grant'),
                  ),
          ),
          ListTile(
            leading: FaIcon(
              _batteryOptimized ? FontAwesomeIcons.solidCircleCheck : FontAwesomeIcons.solidCircleXmark,
              color: _batteryOptimized ? AppColors.textPrimary : AppColors.textQuaternary,
            ),
            title: const Text('Battery Optimization',
                style: AppTextStyles.textMdSemibold),
            subtitle: Text(
              _batteryOptimized
                  ? 'Unrestricted'
                  : 'Needed for background compression',
              style: AppTextStyles.textSmMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            trailing: _batteryOptimized
                ? null
                : TextButton(
                    onPressed: () async {
                      await FlutterForegroundTask
                          .requestIgnoreBatteryOptimization();
                      _checkPermissions();
                    },
                    child: const Text('Grant'),
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.gear),
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
            leading: FaIcon(FontAwesomeIcons.compress,
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
                    _featureRow(FontAwesomeIcons.compress, 'Compress videos with H.264'),
                    _featureRow(
                        FontAwesomeIcons.sliders, 'Configurable resolution, quality & speed'),
                    _featureRow(FontAwesomeIcons.folderOpen, 'Choose output directory'),
                    _featureRow(
                        FontAwesomeIcons.gaugeHigh, 'Asynchronous compression with progress'),
                    _featureRow(
                        FontAwesomeIcons.trashCan, 'Optional original file deletion'),
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
                    _featureRow(FontAwesomeIcons.film, 'FFmpeg 8.0'),
                    _featureRow(FontAwesomeIcons.feather, 'Flutter'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _featureRow(IconData icon, String text) {
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
            child: Center(child: FaIcon(icon, size: 16, color: AppColors.textTertiary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.textSmMedium),
          ),
        ],
      ),
    );
  }
}
