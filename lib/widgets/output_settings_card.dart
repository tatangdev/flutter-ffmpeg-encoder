import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          _AspectRatioPreview(
            aspectRatio: settings.aspectRatio,
            fit: settings.fit,
            rotation: settings.rotation,
            thumbnailFile: thumbnailFile,
            videoWidth: videoWidth,
            videoHeight: videoHeight,
          ),
          const SizedBox(height: 12),
          _buildRotationSelector(),
          const SizedBox(height: 8),
          Text(
            settings.aspectRatio.isOriginal
                ? 'Original resolution'
                : '${settings.resolvedWidth} x ${settings.resolvedHeight}',
            style: AppTextStyles.textSmMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: VideoRotation.values.map((r) {
        final isSelected = settings.rotation == r;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => onChanged(settings.copyWith(rotation: r)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.borderSecondary,
                ),
              ),
              child: Center(
                child: Text(
                  r.label,
                  style: AppTextStyles.textSmSemibold.copyWith(
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAspectRatioDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Aspect Ratio', style: AppTextStyles.textMdSemibold),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: _dropdownDecoration(),
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
          decoration: _dropdownDecoration(),
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
          decoration: _dropdownDecoration(),
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
                            FaIcon(_iconFor(p),
                                size: 18, color: AppColors.textSecondary),
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

  static InputDecoration _dropdownDecoration() => InputDecoration(
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
      );

  IconData _iconFor(VideoPlatform p) => switch (p) {
        VideoPlatform.instagramPost => FontAwesomeIcons.instagram,
        VideoPlatform.instagramReels => FontAwesomeIcons.instagram,
        VideoPlatform.tiktok => FontAwesomeIcons.tiktok,
        VideoPlatform.youtubeShorts => FontAwesomeIcons.youtube,
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
  final VideoRotation rotation;
  final File? thumbnailFile;
  final int? videoWidth;
  final int? videoHeight;

  static const _maxW = 220.0;
  static const _maxH = 200.0;
  static const _animDuration = Duration(milliseconds: 300);
  static const _animCurve = Curves.easeInOut;

  const _AspectRatioPreview({
    required this.aspectRatio,
    required this.fit,
    required this.rotation,
    this.thumbnailFile,
    this.videoWidth,
    this.videoHeight,
  });

  double? get _videoRatio =>
      (videoWidth != null && videoHeight != null && videoHeight! > 0)
          ? videoWidth! / videoHeight!
          : null;

  /// Video ratio after applying rotation (swaps for 90°/270°).
  double? get _effectiveVideoRatio {
    final vr = _videoRatio;
    if (vr == null) return null;
    return rotation.swapsDimensions ? 1.0 / vr : vr;
  }

  double get _displayRatio => aspectRatio.isOriginal
      ? (_effectiveVideoRatio ?? 1.0)
      : aspectRatio.width / aspectRatio.height;

  bool get _isCover => fit == VideoFit.cover || aspectRatio.isOriginal;

  /// Fits [ratio] into [maxW]×[maxH], returning (width, height).
  static (double, double) _fitInBounds(
      double ratio, double maxW, double maxH) {
    if (ratio >= 1) {
      final h = maxW / ratio;
      return h <= maxH ? (maxW, h) : (maxH * ratio, maxH);
    }
    final w = maxH * ratio;
    return w <= maxW ? (w, maxH) : (maxW, maxW / ratio);
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _displayRatio;
    final (frameW, frameH) = _fitInBounds(ratio, _maxW, _maxH);

    // In contain mode, shrink the inner box to the rotated video's
    // proportions so it fits without cropping (black bars on 2 sides).
    var (innerW, innerH) = (frameW, frameH);
    final evr = _effectiveVideoRatio;
    if (!_isCover && evr != null && (evr - ratio).abs() >= 0.01) {
      if (evr > ratio) {
        innerH = frameW / evr;
      } else {
        innerW = frameH * evr;
      }
    }

    return AnimatedContainer(
      duration: _animDuration,
      curve: _animCurve,
      width: frameW,
      height: frameH,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: thumbnailFile != null
          ? OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: AnimatedRotation(
                turns: rotation.degrees / 360.0,
                duration: _animDuration,
                curve: _animCurve,
                child: AnimatedContainer(
                  duration: _animDuration,
                  curve: _animCurve,
                  width: rotation.swapsDimensions ? innerH : innerW,
                  height: rotation.swapsDimensions ? innerW : innerH,
                  child: Image.file(
                    thumbnailFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            aspectRatio.isOriginal
                ? FontAwesomeIcons.expand
                : FontAwesomeIcons.cropSimple,
            size: 28,
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
      return const FaIcon(FontAwesomeIcons.expand,
          size: 18, color: AppColors.textSecondary);
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
