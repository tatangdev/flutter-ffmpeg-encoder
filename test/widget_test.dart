import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devcoder/main.dart';

void main() {
  testWidgets('App renders home screen with select button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VideoCompressorApp());

    expect(find.text('Video Compressor'), findsOneWidget);
    expect(find.text('Select Video'), findsOneWidget);
    expect(find.byIcon(Icons.video_library), findsOneWidget);
  });
}
