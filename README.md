# Video Compressor

A Flutter-based video compression app powered by FFmpeg. Compress videos with configurable resolution, quality, and aspect ratio settings for social media platforms or custom output.

## Features

- **H.264 video compression** via FFmpeg 8.0
- **Social media presets** for Instagram (Post/Reels), TikTok, and YouTube Shorts
- **Custom mode** with configurable resolution (1080p, 2K, 4K) and aspect ratio
- **Crop to fill** or **fit with letterboxing** for non-original aspect ratios
- **Compression queue** with real-time progress tracking
- **Queue persistence** — jobs survive app restarts (SQLite)
- **Draft system** — save and restore video selection and settings
- **Output directory picker** — choose where compressed files are saved
- **Optional original file deletion** after compression
- **Monochrome UI** with Material 3 design

## Tech Stack

- **Flutter** with Material 3
- **FFmpeg** (via `ffmpeg_kit_flutter_new`) for video processing
- **SQLite** (via `sqflite`) for queue and draft persistence
- **OverusedGrotesk** custom font

## Project Structure

```
lib/
├── main.dart                  # App entry point and theme
├── screens/
│   ├── main_shell.dart        # Bottom navigation shell
│   ├── home_screen.dart       # Video selection and settings
│   ├── queue_screen.dart      # Compression job queue
│   └── settings_screen.dart   # Permissions and app info
├── services/
│   ├── compression_queue.dart # Job queue with DB persistence
│   ├── compression_service.dart # FFmpeg command builder
│   ├── database_service.dart  # SQLite database (jobs + drafts)
│   ├── file_service.dart      # File picking, video info, thumbnails
│   └── permission_service.dart # Storage permission handling
├── models/
│   ├── compression_job.dart   # Job data with status tracking
│   ├── compression_settings.dart # Encoding presets and settings
│   ├── compression_result.dart # Compression output metadata
│   ├── video_info.dart        # Video file metadata
│   └── draft.dart             # Draft persistence model
├── widgets/
│   ├── output_settings_card.dart # Settings UI with preview
│   ├── video_info_card.dart   # Video metadata display
│   ├── file_size_comparison.dart # Before/after size comparison
│   ├── empty_state.dart       # Empty state placeholder
│   └── loading_state.dart     # Loading indicator
├── theme/
│   └── app_typography.dart    # Colors and text styles
└── utils/
    ├── constants.dart         # App constants
    ├── file_utils.dart        # File size formatting, path generation
    └── input_sanitizer.dart   # Path validation and sanitization
```

## Getting Started

### Prerequisites

- Flutter SDK ^3.11.0
- Android SDK (for Android builds)

### Setup

```bash
flutter pub get
flutter run
```

### Permissions (Android)

The app requests:
- **Storage / Media Access** — to pick videos and read media
- **All Files Access** — to save compressed files to shared directories (e.g. Movies/)
