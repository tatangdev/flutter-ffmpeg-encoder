import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _channelId = 'compression_progress';
  static const _channelName = 'Compression Progress';
  static const _channelDescription = 'Shows video compression progress';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showProgress({
    required String jobId,
    required String fileName,
    required double progress,
  }) async {
    if (!Platform.isAndroid) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: 100,
      progress: (progress * 100).round(),
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
    );

    await _plugin.show(
      _notificationId(jobId),
      'Compressing: $fileName',
      '${(progress * 100).toStringAsFixed(1)}% complete',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showCompleted({
    required String jobId,
    required String fileName,
    String? savedPercentage,
  }) async {
    if (!Platform.isAndroid) return;

    final body = savedPercentage != null
        ? 'Saved $savedPercentage% file size'
        : 'Compression finished';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
    );

    await _plugin.show(
      _notificationId(jobId),
      'Completed: $fileName',
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showFailed({
    required String jobId,
    required String fileName,
    String? errorMessage,
  }) async {
    if (!Platform.isAndroid) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
    );

    await _plugin.show(
      _notificationId(jobId),
      'Failed: $fileName',
      errorMessage ?? 'Compression failed',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> cancel(String jobId) async {
    if (!Platform.isAndroid) return;
    await _plugin.cancel(_notificationId(jobId));
  }

  int _notificationId(String jobId) => jobId.hashCode;
}
