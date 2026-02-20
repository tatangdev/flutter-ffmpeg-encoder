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
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.borderSecondary),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _switchTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.compress),
                selectedIcon: Icon(Icons.compress),
                label: 'Compress',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_outlined),
                selectedIcon: Icon(Icons.queue),
                label: 'Queue',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
