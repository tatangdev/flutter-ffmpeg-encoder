import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devcoder/main.dart';

void main() {
  testWidgets('App renders with bottom navigation and compress tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VideoCompressorApp());

    // Bottom nav items
    expect(find.text('Compress'), findsOneWidget);
    expect(find.text('Queue'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Home screen content
    expect(find.text('Video Compressor'), findsOneWidget);
    expect(find.text('Select Video'), findsOneWidget);
    expect(find.byIcon(Icons.video_library), findsOneWidget);
  });
}
