import 'dart:io';

import 'package:flutter/material.dart';

import '../models/compression_settings.dart';
import '../theme/app_typography.dart';

class OutputSettingsCard extends StatelessWidget {
  final CompressionSettings settings;
  final ValueChanged<CompressionSettings> onChanged;
  final File? thumbnailFile;
  final int? videoWidth;
  final int? videoHeight;

  const OutputSettingsCard({
    super.key,
    required this.settings,
    required this.onChanged,
    this.thumbnailFile,
    this.videoWidth,
    this.videoHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Output Settings', style: AppTextStyles.textLgSemibold),
            const SizedBox(height: 16),

            // ── Preview ──
            _buildPreviewSection(),
            const SizedBox(height: 20),

            // ── Export Quality section ──
            const Text('Export Quality', style: AppTextStyles.textMdSemibold),
            const SizedBox(height: 8),

            _ExportModeSelector(
              selected: settings.exportMode,
              onChanged: (m) {
                if (m == ExportMode.socialMedia) {
                  // Auto-set aspect ratio based on current platform
                  final ar = settings.platform == VideoPlatform.instagramPost
                      ? VideoAspectRatio.original
                      : VideoAspectRatio.portrait16x9;
                  onChanged(settings.copyWith(exportMode: m, aspectRatio: ar));
                } else {
                  onChanged(settings.copyWith(exportMode: m));
                }
              },
            ),
            const SizedBox(height: 20),

            // ── Aspect Ratio (custom mode only) ──
            if (settings.exportMode == ExportMode.custom) ...[
              _buildAspectRatioDropdown(),
              const SizedBox(height: 20),
            ],

            if (settings.exportMode == ExportMode.custom)
              _buildCustomSection()
            else
              _buildSocialMediaSection(),

            // ── Crop toggle (non-original aspect ratio) ──
            if (!settings.aspectRatio.isOriginal) ...[
              const SizedBox(height: 12),
              _buildToggleRow(
                label: 'Crop to fill',
                subtitle: settings.fit == VideoFit.cover
                    ? 'Fills frame, crops overflow'
                    : 'Fits entire video, adds black bars',
                value: settings.fit == VideoFit.cover,
                onChanged: (v) => onChanged(settings.copyWith(
                  fit: v ? VideoFit.cover : VideoFit.contain,
                )),
              ),
            ],

            const SizedBox(height: 12),

            // ── Optimize storage toggle ──
            _buildToggleRow(
              label: 'Optimize storage',
              subtitle: settings.tier == QualityTier.balanced
                  ? 'Smaller file size, slightly reduced quality'
                  : 'Best quality, larger file size',
              value: settings.tier == QualityTier.balanced,
              onChanged: (v) => onChanged(settings.copyWith(
                tier: v ? QualityTier.balanced : QualityTier.best,
              )),
            ),

            const SizedBox(height: 12),

            // ── Delete original ──
            _buildToggleRow(
              label: 'Delete original',
              subtitle: 'Remove source file after compression',
              value: settings.deleteOriginal,
              onChanged: (v) =>
                  onChanged(settings.copyWith(deleteOriginal: v)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared toggle row ──

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.textMdSemibold),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.textSmMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ── Aspect Ratio ──

  Widget _buildPreviewSection() {
    return Column(
      children: [
        Center(
          child: _AspectRatioPreview(
            aspectRatio: settings.aspectRatio,
            fit: settings.fit,
            thumbnailFile: thumbnailFile,
            videoWidth: videoWidth,
            videoHeight: videoHeight,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            settings.aspectRatio.isOriginal
                ? 'Original resolution'
                : '${settings.resolvedWidth} x ${settings.resolvedHeight}',
            style: AppTextStyles.textSmMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAspectRatioDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aspect Ratio', style: AppTextStyles.textMdSemibold),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VideoAspectRatio>(
              value: settings.aspectRatio,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items: VideoAspectRatio.values
                  .map((ar) => DropdownMenuItem(
                        value: ar,
                        child: Row(
                          children: [
                            _AspectRatioIcon(aspectRatio: ar),
                            const SizedBox(width: 12),
                            Text(ar.label, style: AppTextStyles.textMdRegular),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (ar) {
                if (ar != null) {
                  onChanged(settings.copyWith(aspectRatio: ar));
                }
              },
            ),
          ),
        ),

      ],
    );
  }

  // ── Export Quality sections ──

  Widget _buildCustomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resolution', style: AppTextStyles.textMdSemibold),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CustomResolution>(
              value: settings.customResolution,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items: CustomResolution.values
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text('${r.label} - ${r.description}',
                            style: AppTextStyles.textMdRegular),
                      ))
                  .toList(),
              onChanged: (r) {
                if (r != null) {
                  onChanged(settings.copyWith(customResolution: r));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          settings.customResolution.description,
          style: AppTextStyles.textSmMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Platform', style: AppTextStyles.textMdSemibold),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSecondary),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<VideoPlatform>(
              value: settings.platform,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items: VideoPlatform.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(_iconFor(p),
                                size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(p.label, style: AppTextStyles.textMdRegular),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (p) {
                if (p != null) {
                  final ar = p == VideoPlatform.instagramPost
                      ? VideoAspectRatio.original
                      : VideoAspectRatio.portrait16x9;
                  onChanged(settings.copyWith(platform: p, aspectRatio: ar));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _constraintText(settings.platform),
          style: AppTextStyles.textSmMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── Helpers ──

  IconData _iconFor(VideoPlatform p) => switch (p) {
        VideoPlatform.instagramPost => Icons.photo_outlined,
        VideoPlatform.instagramReels => Icons.camera_alt_outlined,
        VideoPlatform.tiktok => Icons.music_note_outlined,
        VideoPlatform.youtubeShorts => Icons.play_circle_outline,
      };

  String _constraintText(VideoPlatform p) => switch (p) {
        VideoPlatform.instagramPost =>
          'Original ratio \u2022 Max 4GB \u2022 H.264 30fps',
        VideoPlatform.instagramReels =>
          '1080x1920 \u2022 Max 4GB \u2022 H.264 30fps',
        VideoPlatform.tiktok =>
          '1080x1920 \u2022 Android 72MB limit \u2022 H.264 30fps',
        VideoPlatform.youtubeShorts =>
          '1080x1920 \u2022 Max 180 seconds \u2022 H.264 30fps',
      };
}

// ── Private widgets (moved from aspect_ratio_card.dart) ──

class _AspectRatioPreview extends StatelessWidget {
  final VideoAspectRatio aspectRatio;
  final VideoFit fit;
  final File? thumbnailFile;
  final int? videoWidth;
  final int? videoHeight;

  const _AspectRatioPreview({
    required this.aspectRatio,
    required this.fit,
    this.thumbnailFile,
    this.videoWidth,
    this.videoHeight,
  });

  @override
  Widget build(BuildContext context) {
    const maxHeight = 200.0;
    const maxWidth = 220.0;

    double previewWidth;
    double previewHeight;

    if (aspectRatio.isOriginal) {
      if (videoWidth != null && videoHeight != null && videoHeight! > 0) {
        final ratio = videoWidth! / videoHeight!;
        if (ratio >= 1) {
          previewWidth = maxWidth;
          previewHeight = maxWidth / ratio;
          if (previewHeight > maxHeight) {
            previewHeight = maxHeight;
            previewWidth = maxHeight * ratio;
          }
        } else {
          previewHeight = maxHeight;
          previewWidth = maxHeight * ratio;
          if (previewWidth > maxWidth) {
            previewWidth = maxWidth;
            previewHeight = maxWidth / ratio;
          }
        }
      } else {
        previewWidth = 160;
        previewHeight = 160;
      }
    } else {
      final ratio = aspectRatio.width / aspectRatio.height;
      if (ratio >= 1) {
        previewWidth = maxWidth;
        previewHeight = maxWidth / ratio;
        if (previewHeight > maxHeight) {
          previewHeight = maxHeight;
          previewWidth = maxHeight * ratio;
        }
      } else {
        previewHeight = maxHeight;
        previewWidth = maxHeight * ratio;
        if (previewWidth > maxWidth) {
          previewWidth = maxWidth;
          previewHeight = maxWidth / ratio;
        }
      }
    }

    final hasThumbnail = thumbnailFile != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: previewWidth,
      height: previewHeight,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasThumbnail
          ? _buildThumbnailPreview(previewWidth, previewHeight)
          : _buildPlaceholder(),
    );
  }

  Widget _buildThumbnailPreview(double containerW, double containerH) {
    if (aspectRatio.isOriginal) {
      return Image.file(
        thumbnailFile!,
        width: containerW,
        height: containerH,
        fit: BoxFit.cover,
      );
    }

    final targetRatio = aspectRatio.width / aspectRatio.height;
    final videoRatio =
        (videoWidth != null && videoHeight != null && videoHeight! > 0)
            ? videoWidth! / videoHeight!
            : targetRatio;

    double containScale;
    if ((videoRatio - targetRatio).abs() < 0.01) {
      containScale = 1.0;
    } else if (videoRatio > targetRatio) {
      containScale = targetRatio / videoRatio;
    } else {
      containScale = videoRatio / targetRatio;
    }

    final targetScale = fit == VideoFit.cover ? 1.0 : containScale;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: targetScale),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Container(
          color: Colors.black,
          width: containerW,
          height: containerH,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Image.file(
        thumbnailFile!,
        width: containerW,
        height: containerH,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            aspectRatio.isOriginal
                ? Icons.crop_free
                : aspectRatio.height > aspectRatio.width
                    ? Icons.crop_portrait
                    : Icons.crop_landscape,
            size: 32,
            color: AppColors.accent,
          ),
          const SizedBox(height: 4),
          Text(
            aspectRatio.isOriginal ? 'Original' : aspectRatio.label,
            style: AppTextStyles.textSmSemibold.copyWith(
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportModeSelector extends StatelessWidget {
  final ExportMode selected;
  final ValueChanged<ExportMode> onChanged;

  const _ExportModeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = ExportMode.values.length;
    final selectedIndex = ExportMode.values.indexOf(selected);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSecondary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment(
              -1.0 + (2.0 * selectedIndex / (count - 1)),
              0.0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1.0 / count,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),

          // Labels
          Row(
            children: ExportMode.values.map((m) {
              final isSelected = selected == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(m),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      style: AppTextStyles.textMdSemibold.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      child: Text(m.label),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AspectRatioIcon extends StatelessWidget {
  final VideoAspectRatio aspectRatio;

  const _AspectRatioIcon({required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    if (aspectRatio.isOriginal) {
      return const Icon(Icons.fullscreen,
          size: 22, color: AppColors.textSecondary);
    }

    const maxDim = 20.0;
    final ratio = aspectRatio.width / aspectRatio.height;
    final double w;
    final double h;
    if (ratio >= 1) {
      w = maxDim;
      h = maxDim / ratio;
    } else {
      h = maxDim;
      w = maxDim * ratio;
    }

    return SizedBox(
      width: 22,
      height: 22,
      child: Center(
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textSecondary, width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
