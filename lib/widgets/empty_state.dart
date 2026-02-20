import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_typography.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onSelectVideo;

  const EmptyState({super.key, required this.onSelectVideo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: FaIcon(FontAwesomeIcons.photoFilm,
                size: 36, color: AppColors.textQuaternary)),
          ),
          const SizedBox(height: 16),
          Text(
            'No video selected',
            style: AppTextStyles.textMdSemibold.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a video to configure compression settings',
            style: AppTextStyles.textSmMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSelectVideo,
            icon: const FaIcon(FontAwesomeIcons.photoFilm),
            label: const Text('Select Video'),
          ),
        ],
      ),
    );
  }
}
