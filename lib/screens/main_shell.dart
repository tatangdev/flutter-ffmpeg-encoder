import 'package:flutter/material.dart';

import '../services/compression_queue.dart';
import '../services/database_service.dart';
import '../theme/app_typography.dart';
import 'queue_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final DatabaseService _databaseService;
  late final CompressionQueue _compressionQueue;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _compressionQueue = CompressionQueue(_databaseService);
    _initQueue();
  }

  Future<void> _initQueue() async {
    await _compressionQueue.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _compressionQueue.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildNavItem(IconData icon, IconData selectedIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF9C9C9C);
    return GestureDetector(
      onTap: () => _switchTab(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              compressionQueue: _compressionQueue,
              databaseService: _databaseService,
              onSwitchTab: _switchTab,
            ),
            QueueScreen(compressionQueue: _compressionQueue),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.borderSecondary),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.compress, Icons.compress, 'Compress', 0),
              _buildNavItem(Icons.queue_outlined, Icons.queue, 'Queue', 1),
              _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 2),
            ],
          ),
        ),
      ),
    );
  }
}
