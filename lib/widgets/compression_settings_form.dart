import 'package:flutter/material.dart';

import '../models/compression_settings.dart';

class CompressionSettingsForm extends StatelessWidget {
  final CompressionSettings settings;
  final ValueChanged<CompressionSettings> onChanged;

  const CompressionSettingsForm({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compression Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Resolution
            _dropdown<VideoResolution>(
              label: 'Resolution',
              value: settings.resolution,
              items: VideoResolution.values,
              itemLabel: (v) => v.label,
              onChanged: (v) => onChanged(settings.copyWith(resolution: v)),
            ),
            const SizedBox(height: 8),

            // Quality
            _dropdown<VideoQuality>(
              label: 'Quality',
              value: settings.quality,
              items: VideoQuality.values,
              itemLabel: (v) => v.label,
              onChanged: (v) => onChanged(settings.copyWith(quality: v)),
            ),
            const SizedBox(height: 8),

            // Preset (speed)
            _dropdown<CompressionPreset>(
              label: 'Speed',
              value: settings.preset,
              items: CompressionPreset.values,
              itemLabel: (v) => v.label,
              onChanged: (v) => onChanged(settings.copyWith(preset: v)),
            ),
            const SizedBox(height: 12),

            // Delete original toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Delete original after compression'),
              value: settings.deleteOriginal,
              onChanged: (v) =>
                  onChanged(settings.copyWith(deleteOriginal: v)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: DropdownButtonFormField<T>(
            initialValue: value,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(),
            ),
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(itemLabel(item)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}
