import 'package:flutter/material.dart';

import '../services/compression_queue.dart';
import '../services/file_service.dart';
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
  late final FileService _fileService;
  late final CompressionQueue _compressionQueue;

  @override
  void initState() {
    super.initState();
    _fileService = FileService();
    _compressionQueue = CompressionQueue(_fileService);
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
              onSwitchTab: _switchTab,
            ),
            QueueScreen(compressionQueue: _compressionQueue),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
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
    );
  }
}
